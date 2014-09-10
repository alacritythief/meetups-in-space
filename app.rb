require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/flash'
require 'omniauth-github'

require_relative 'config/application'

Dir['app/**/*.rb'].each { |file| require_relative file }

helpers do
  def current_user
    user_id = session[:user_id]
    @current_user ||= User.find(user_id) if user_id.present?
  end

  def signed_in?
    current_user.present?
  end
end

def set_current_user(user)
  session[:user_id] = user.id
end

def authenticate!
  unless signed_in?
    flash[:notice] = 'You need to sign in if you want to do that!'
    redirect '/'
  end
end

get '/' do
  erb :index
end

get '/auth/github/callback' do
  auth = env['omniauth.auth']

  user = User.find_or_create_from_omniauth(auth)
  set_current_user(user)
  flash[:notice] = "You're now signed in as #{user.username}!"

  redirect '/'
end

get '/sign_out' do
  session[:user_id] = nil
  flash[:notice] = "You have been signed out."

  redirect '/'
end

get '/example_protected_page' do
  authenticate!
end

get '/meetups' do
  @meetups = Meetup.all.order(:name)
  erb :'meetups/index'
end

post '/search' do
  name = params['name']
  des = params['description']
  loc = params['location']

  @results = Meetup.all.where("name like ? and description like? and location like?", "%#{name}%", "%#{des}%", "%#{loc}%").order(:name)
  erb :search
end

get '/meetups/new' do
  erb :'meetups/new'
end

get '/meetups/:id' do
  @meetup = Meetup.find(params[:id])
  erb :'meetups/show'
end

post '/meetups/new' do
  authenticate!

  name = params['name']
  des = params['description']
  loc = params['location']

  @new_meetup = Meetup.new(name: name, description: des, location: loc)
  if @new_meetup.name != "" && @new_meetup.description != "" && @new_meetup.location != ""
    redirect "/meetups/#{@new_meetup.id}"
  else
    flash[:notice] = 'Please complete all fields!'
    redirect '/meetups/new'
  end
end

post '/meetups/:meetup_id/memberships' do
  authenticate!

  @meetup = Meetup.find(params[:meetup_id])
  @membership = Membership.new(user_id: current_user.id, meetup_id: @meetup.id)

  if @membership.save
    flash[:notice] = "You successfully joined the meetup!"
    redirect "/meetups/#{@meetup.id}"
  else
    flash[:notice] = "ERROR: Cannot Join Meetup"
    redirect "/meetups/#{@meetup.id}"
  end
end
