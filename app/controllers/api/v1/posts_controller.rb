class Api::V1::PostsController < Api::V1::BaseApiController
  #prepend_before_filter :require_no_authentication, :only => [:show, :show_comments, :frontpage, :new, :ask]
  before_filter :authenticate_user!, => :only => [:create, :vote]

  # POST /posts
  def create
    @post = Post.new(params[:post])
    @post.user_id = current_user.id

    if @post.save
	  current_user.up_vote!(@post)
      render :json => @post, :status => :created, :location => @post
    else
      render :json => @post.errors, :status => :unprocessable_entity
    end
  end

  # GET /posts
  def show
  	puts 'hello'
    @post = Post.find(params[:id])
    @parent_comments = @post.comments

    render :json => @post
  end

  # GET /posts/:id/comments
  def show_comments
  	@post = Post.find(params[:id])
    @parent_comments = @post.comments

    render :json => @post.comments
  end

  # PUT /posts/:id/vote
  def vote
    if current_user.nil? then
      render :json => {:success => false, :message => "Please login"}, :status => 401
      return
    end
    post = Post.find(params[:id])
    if post.nil? then
      render :json => {:success => false, :message => "Couldn't find post with id #{params[:id]}"}, :status => 401
      return
    end
    current_user.up_vote(post)
    render :json => {:success => true, :message => "Successfully voted up"}, :status => 200
  end

  # GET /posts/frontpage
  # GET /posts/frontpage/page/:page
  def frontpage
    (params[:page].nil? or params[:page].to_i < 1) ? @page = 1 : @page = params[:page].to_i
    offset = ((@page-1)*20)
    @posts = Post.find_by_sql ["SELECT * FROM posts ORDER BY ((posts.up_votes - posts.down_votes) -1 )/POW((((UNIX_TIMESTAMP(NOW()) - UNIX_TIMESTAMP(posts.created_at)) / 3600 )+2), 1.5) DESC LIMIT ?, 20", offset]
    render :json => @posts
  end

  # GET /posts/new
  # GET /posts/new/page/:page
  def new
    (params[:page].nil? or params[:page].to_i < 1) ? @page = 1 : @page = params[:page].to_i
    offset = ((@page-1)*20)
    @posts = Post.find(:all, :order => "created_at DESC", :limit => 20, :offset => offset)
    render :json => @posts
  end
  
  # GET /posts/ask
  # GET /posts/ask/page/:page
  def ask
  	(params[:page].nil? or params[:page].to_i < 1) ? @page = 1 : @page = params[:page].to_i
    offset = ((@page-1)*20)
    @posts = Post.find_by_sql ["SELECT * FROM posts WHERE posts.link = '' ORDER BY ((posts.up_votes - posts.down_votes) -1 )/POW((((UNIX_TIMESTAMP(NOW()) - UNIX_TIMESTAMP(posts.created_at)) / 3600 )+2), 1.5) DESC LIMIT ?, 20", offset]
    render :json => @posts
  end

end
