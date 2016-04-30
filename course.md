# Building a JSON API using Rails

# Introduction

Ruby on Rails has always been a popular backend of choice in the web development
community. It emphasizes the [configuration over convention](https://en.wikipedia.org/wiki/Convention_over_configuration)
programming paradigm, taking care of the most common use cases out of the box,
allowing the programmer to get up and running fast and focus on the code that's
unique to their application instead of reinventing the wheel. As web development
technologies have evolved over the years with the increased popularity of
Javascript frameworks and [single-page applications](https://en.wikipedia.org/wiki/Single-page_application),
Rails is often not the first backend of choice since a lot of the concerns
it handles have now been delegated to the front end (such as rendering templates,
build systems etc.), leaving people with the impression that Rails provides
*too much* out of the box, and that they're better off finding a lighter
framework to use as an API. While the criticism is valid, Rails is far from
dead. With a little configuration, Rails can easily be fitted for use as a JSON
API, letting developers continue to reap the many design decisions made by
the Rails community and the agile development speed Rails allows.

This course will teach you how to use Rails4 as a JSON API. We will be building a
backend that will provide the functionality for a [Medium](https://medium.com)
clone called [Conduit](https://demo.productionready.io). Note that this course
only goes over how to build the backend in Rails. Once the backend is completed,
you can pair it with our [AngularJS course](https://thinkster.io/angularjs-es6-tutorial)
to get the entire application running.

# Prerequisites

We've provided a specification for our API that we will be building. We
recommended that you go over all the endpoints in the specification and play
around with the demo to get a good idea of the application.

{x: read API docs}
Review the [API documentation](https://github.com/GoThinkster/productionready/blob/master/API.md)

This course assumes some basic Rails knowledge. We'll be using JWT tokens with
[Devise](https://github.com/plataformatec/devise) for authentication, along with
[Jbuilder](https://github.com/rails/jbuilder) for rendering JSON. We recommend
using PostgreSQL as your database, but since we're using ActiveRecord, you have
the choice of using SQLite, PostgreSQL, MySQL, or any other ActiveRecord
compatible database.

{x: install rails4}
Install Rails (at the time of writing, this course is using version 4.2.6).
Instructions for installing Rails can be found [here](http://railsapps.github.io/installing-rails.html)

{x: clone seed repo}
Clone the [seed repository](https://github.com/GoThinkster/conduit-rails4)

The seed repository has all the gems required for this project installed. We've
used SQLite in the repository for easier setup, but it is recommended that you
switch to something like PostgreSQL or MySQL if you intend on using your
project in production. While SQLite is easy to use and setup, it has some
limitations that make it unsuitable for production, the main one being that
the database lives on your filesystem, making running multiple servers
difficult and locking the database file on writes.

{x: db swap}
OPTIONAL: Swap our your database to PostgreSQL or MySQL. You'll need to replace
the `sqlite3` gem in your gemfile with either `postgresql` or `mysql2` and
update `database.yml` with the correct adapter. You'll also need to make sure
that your database is installed, running, and have a user set up in your
database for your application.

{x: run bundle install}
Run `bundle install` to install all the required gems for this proejct.

# Setting up Users and Authentication for our API

[Devise](https://github.com/plataformatec/devise) is an excellent
authentication system made for Rails that allows us to easily drop-in User
functionality into our project. We'll have to make some changes to our
controllers authenticate with JWT's since Devise uses session authentication by
default.

## Creating the User Model

{x: generate devise config}
Generate the devise initializer by running `rails generate devise:install`

{x: generate user model}
Generate your user model by running `rails generate devise User`

For our user profiles, we'll also need a few extra fields in addition to the
ones Devise generates by default to store usernames, image URLs and user bio's.
Let's go ahead and create a migration to add those columns to our User

{x: generate profile fields}
`rails g migration AddProfileFieldsToUsers username:string:uniq image:string bio:text`

This migration creates a username, image and bio fields for our User. Providing
the `uniq` option to username creates a unique index for that column.

We should now have all the migrations necessary for creating our users table.
Let's go ahead and run these migrations to apply them to our database.

{x: migrate user creation}
Run `rake db:migrate`

Once the migration is finished, we should have our Users table created in our
database and a User model generated in `app/models/user.rb`.

## Configuring Routes for the API

Since we want all our routes to start with `/api`, we can use a `scope` in our
router to prefix our routes, and pass additonal options to them. We'll
want to pass `defaults: { format: :json }` to our scope so that our controllers
know that requests will be JSON requests by default.

{x: scope routes}
In `config/routes.rb`, wrap the devise routes in a `scope :api` block, and pass in the options
`defaults: { format: :json }` to the `scope` method

```ruby
  scope :api, defaults: { format: :json } do
    devise_for :users
  end
```

Since we'll be using using JWT for authentication, and Rails isn't currently serving
our front-end, we won't be needing to check for CSRF tokens on our requests.

{x: disable csrf exceptions }
Update `protect_from_forgery with: :exception` to `protect_from_forgery with: :null_session` in `app/controllers/application_controller.rb`

CSRF is usually checked on non-GET requests, and by default if no CSRF token is
provided Rails will throw an exception, causing our requests to fail. The
`:null_session` setting will clear out our session variables instead of causing
an exception to be thrown.

In order to let our controllers know that they need to respond with json, we'll
also need to add the following line in `application_controller.rb`

{x: respond to json}
`respond_to :json`

Finally, we want our clients to be able to submit their payloads using
lowerCamelCase, and our responses should be lowerCamelCase as well. Since we'll
be using Jbuilder for rendering JSON responses, we can use an initializer to
configure Jbuilder to output all JSON keys in lowerCamelCase

{x: create jbuilder initializer}
Create an initializer in `config/initializers/jbuilder.rb` with the following code:

```ruby
Jbuilder.key_format camelize: :lower
```

In order to keep using snake_case throughout our app, we'll have to convert
any incoming parameters in our application to snake_case. This can be achieved
by using a [`before_action` filter](http://guides.rubyonrails.org/action_controller_overview.html#filters)
in `application_controller.rb`

{x: create underscore params}
Create the following private method in `application_controller.rb`

```ruby
  def underscore_params!
    params.deep_transform_keys!(&:underscore)
  end
```

{x: before_action underscore}
Add a before_action filter to `action_controller.rb`

```ruby
  before_action :underscore_params!
```

Changing our parameters to snake_case has a couple advantages, it keeps our code
looking clean and Ruby-ish (instead of having to reference lowerCamelCase
parameters), and it allows us to pass our parameters to model methods like
`update_attributes` on our models without having to worry about case conversion.

## Setting up Registration and Login

{x: user generate_jwt}
Create the following function in `app/models/user.rb`

```ruby
def generate_jwt
  JWT.encode({ id: self.id,
              exp: 60.days.from_now.to_i },
             Rails.application.secrets.secret_key_base)
end
```

In our JWT payload, we're including the id of the user, and setting the
expiration time of the token to 60 days in the future. We're using the
`secret_key_base` that rails usually uses for cookies to sign our JWT tokens
(we won't be using cookies on our server) you can choose to create a different
secret if you'd like. In production this key will be set using an environment
variable.

While we're in `app/models/user.rb`, let's add a validation for usernames.

{x: add username validation}
Add the following validation to the User model

```ruby
  validates :username, uniqueness: true, presence: true, allow_blank: false
```

This validation makes sure that all users that sign up have unique usernames,
and that users must have usernames when signing up. Now, let's go ahead and set
up our views for rendering JSON responses.

{x: create views user folder}
Create a folder in `app/views` called `users`

{x: create user json partial}
Create the following partial in `app/views/users` called `_user.json.jbuilder`:

```ruby
json.(user, :id, :email, :username, :bio, :image)
json.token user.generate_jwt
```

This JSON partial will be used by our controllers whenever we're dealing with
authentication. It contains the user's JWT token which is considered sensitive,
so be the partial only ever gets rendered for the current user. Later down the
road, we'll create a partial for user profiles which will be public-facing. In
order for Devise to use jbuilder template we just created, we'll need to create
a couple jbuilder views in Devise's template folders. We're only going to be
using two of Devise's endpoints in our API, registration and logging in.

{x: create devise views folder}
Create a folder in `app/views` called `devise`

{x: create registration }
Create two folders named `registrations` and `sessions` in `app/views/devise`

{x: user create json jbuilder}
Create the following template in the `registrations` and `sessions` folder you
just created and name them `create.json.jbuilder`

```ruby
json.user do |json|
  json.partial! 'users/user', user: current_user
end
```

Next, let's have to override the `create` method on Devise's `SessionController`
in order to customize the response behavior of the login endpoint. By default,
Devise responds with a 401 status code when authentication fails, and formats
the error JSON as `{error: 'Invalid username or password'}`. We want our login
endpoint to respond with a 422 status code, and the body to follow the errors
format in the [documentation](https://github.com/GoThinkster/productionready/blob/master/API.md#errors).

{x: create sessionscontroller}
Create the following file in `app/controllers/sessions_controller.rb`

```ruby
class SessionsController < Devise::SessionsController
  def create
    user = User.find_by_email(sign_in_params[:email])

    if user && user.valid_password?(sign_in_params[:password])
      @current_user = user
    else
      render json: { errors: { 'email or password' => ['is invalid'] } }, status: :unprocessable_entity
    end
  end
end
```

{x: customize devise_for}
Now we need to let Devise that we want to override `SessionController`. We also
need to make our login route `/api/users/login` instead of the default
`/api/users/sign_in` We can do this by adding the following configuration to
the `devise_for` call in `config/routes.rb`

```ruby
  scope :api, defaults: { format: :json } do
    devise_for :users, controllers: { sessions: :sessions },
                       path_names: { sign_in: :login }
  end
```

By default, Devise doesn't allow addition fields beyond `email` and `password`.
We'll need to add some code in `app/controllers/application_controller.rb` to
allow our users to provide usernames on registration. The [Devise Readme](https://github.com/plataformatec/devise/tree/3-stable#strong-parameters)
has instructions on how to do this which we'll be following

{x: create configure_permitted_parameters}
Under the `private` keyword in `app/controllers/application_controller.rb`,
create the following `configure_permitted_parameters` function:

```ruby
  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :username
  end
```

Private methods in our controllers make sure that we can't mistakenly use them
as controller actions, which usually require something to be rendered. Next,
we'll need our controllers to call this function only if they're a Devise
controller

{x: before_action configure_permitted_parameters}
Add the following `before_action` filter after the `underscore_params!` filter
line in `application_controller.rb`

```diff
  before_action :underscore_params!
+ before_action :configure_permitted_parameters, if: :devise_controller?
```

Before we can test our authentication endpoints, we'll need to override the way
Devise figures out which user is logged in. Usually devise retrieves this
information from cookies, but for our API we'll need to check the Authorization
header of our request for a JWT token and get the logged in user from that.

{x: create soft auth method}
Create the following private `authenticate_user` method in `application_controller.rb`

```ruby
  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :username
  end

  def authenticate_user
    if request.headers['Authorization'].present?
      authenticate_or_request_with_http_token do |token|
        begin
          jwt_payload = JWT.decode(token, Rails.application.secrets.secret_key_base).first

          @current_user_id = jwt_payload['id']
        rescue JWT::ExpiredSignature, JWT::VerificationError, JWT::DecodeError
          head :unauthorized
        end
      end
    end
  end
```

Here we're checking the incoming request for an Authorization header. The
`authenticate_or_request_with_http_token` is part of Rails and will grab the
token from the Authorization header if it's in the format
`Authorization: Token jwt.token.here` This conveniently gives us just the JWT,
whereas if we just looked at the Authorization token we'd need to strip out the
`Token ` part before the JWT. Next, we'll attempt to decode the token. If that
fails by throwing any JWT exception, we'll rescue it and send a 401 back to the
client. The decode method also throws exceptions for expired tokens. If we can
successfully decode the token, we'll grab the `id` value from the payload, and
set it to the instance variable `@current_user_id` for later use (all of our
controllers inherit from `ApplicationController` so we'll be able to use this
value from any of our controllers). We're also avoiding any database calls,
deferring any queries for the user for when we actually need it.

{x: before_action soft authenticate}
Add a `before_action` filter in `application_controller.rb` specifying `:authenticate_user`

The top part of your `application_controller.rb` (before the `private` keyword)
should look similar to this:

```ruby
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  before_action :underscore_params!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user
```

Note that although we're calling `:authenticate_user` on each request, we only
inturrupt the request if the JWT token is invalid, but not if the JWT token
is missing. This allows requests that don't require authentication to continue.
Next, let's override the `authenticate_user!`, `current_user` and `signed_in?`
methods from Devise in `application_controller.rb`

{x: finish devise override}
Add the following private methods to `application_controller.rb`

```ruby
  def authenticate_user!(options = {})
    head :unauthorized unless signed_in?
  end

  def current_user
    @current_user ||= super || User.find(@current_user_id)
  end

  def signed_in?
    @current_user_id.present?
  end
```

Now we can access `current_user` and use `signed_in?` throughout our
application as if we were using Devise without JWT's, allowing us to access the
current user and checking if a user's signed in using the same syntax.
`authenticate_user!` can also be used the same way as a `before_action`
filter, allowing us to reject requests the require authentication using the
familiar Devise syntax.

Finally, let's create a couple endpoints for a user to update and retrieve their
own information.

{x: create user resource route}
Add a `:user` resource to `config/routes.rb`

```ruby
  scope :api, defaults: { format: :json } do
    devise_for :users, controllers: { sessions: :sessions },
                       path_names: { sign_in: :login }

    resource :user, only: [:show, :update]
  end
```

By default rails creates 6 routes for [singular resources](http://guides.rubyonrails.org/routing.html#singular-resources).
We only need to get and update users, so we're passing `only: [:show, :update]`
to the resource. This makes it so that only a `GET` and `PUT/PATCH` route is
made.

{x: create users controller}
Create `app/controllers/users_controller.rb` with the following code:

```ruby
class UsersController < ApplicationController
  before_action :authenticate_user!
end
```

{x: create user strong params}
Create a private function for getting whitelisted user params

```ruby
  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :bio, :image)
  end
```

This is the strong parameters syntax introduced in Rails 4. Only values we
specified within `permit` will be available when we call `user_params`, any
values in params not listed in `permit` will be dropped. Additionally, any
requests without a `user` in the request will result in a 400 status code.

{x: create users show action}
Create the `show` action for `UsersController`

```diff
+ def show
+ end

  private

  def user_params
```

Since we'll be using `current_user` later in our template for `show`, we don't
need to include any logic in our `show` action.

{x: create users update action}
Create the following `update` action for `UsersController` to allow users to
edit their profiles

```diff
  def show
  end

+ def update
+   if current_user.update_attributes(user_params)
+     render :show
+   else
+     render json: { errors: current_user.errors }, status: :unprocessable_entity
+   end
+ end

  private
```

Since both the `show` and `update` actions will render the user JSON, we can
call `render :show` in our update action to reuse the same template from `show`.
Let's go ahead and create those templates.

{x: update show user jbuilder}
In `app/views/users`, create `show.json.jbuilder` with the following code:

```ruby
json.user do |json|
  json.partial! 'users/user', user: current_user
end
```

## Testing Authentication with Postman

Now we can to start our Rails server using `rails s`. We should be able to run
all of the requests in the `Auth` folder of the Postman. The Login and Register
requests in Postman automatically save the returned JWT tokens as environment
variables within Postman, allowing you to use requests for getting and updating
the current user without setting the Authorization header manually. After
registering a user, you should be able to log in with the same credentials and
update the fields of that user. You can customize the parameters being sent by
Postman in the Body tab of each request.

{x: test registration postman}
Create an account using the Register request in Postman

{x: test login postman}
Test the Login endpoint using Postman

{x: test registration error postman}
Try registering another user with the same email or username, you should get
an error back from the backend

{x: test login error postman}
Try logging in to the user you created with an invalid password, you should get
an error back from the backend

{x: test user fetch postman}
Test the Current User endpoint using Postman

{x: test update user postman}
Try updating the email, username, bio, or image for the user


# Creating the Endpoint for Public Profiles

Now that we have our User model and Authentication all good to go, let's create
an endpoint for retrieving user profiles. Profiles are for users' public-facing
data (no emails, tokens, etc). We should be able to look up users by their
username and get their information.

{x: create profile resource}
Create a resource in `config/routes.rb` for profiles:

```diff
Rails.application.routes.draw do
  scope :api, defaults: { format: :json } do
    devise_for :users, controllers: { sessions: :sessions },
                       path_names: { sign_in: :login }

    resource :user, only: [:show, :update]
+
+   resources :profiles, param: :username, only: [:show]
  end
end
```

Since we're going to be looking up profiles by username, we'll pass in
`param: :username` as an option for the resource. By default, resources are
looked up by `:id` in Rails. We also only need a `GET` route, which is why
we specify `only: [:show]`

{x: create profiles controller}
Create `app/controllers/profiles_controller.rb` with the following code:

```ruby
class ProfilesController < ApplicationController
  def show
    @user = User.find_by_username!(params[:username])
  end
end
```

The bang (`!`) in the `find_by_username!` query will throw an exception if a
user can't be found with that username. In production this will simply send a
a 404 status code back to the client. Next, let's define the template for
our profiles

{x: create profiles view folder}
Create a folder in `app/views` named `profiles`.

{x: create profiles partial}
Create the following partial for profiles in
`app/views/profiles/_profile.json.jbuilder`:

```ruby
json.(user, :username, :bio)
json.image user.image || 'https://static.productionready.io/images/smiley-cyrus.jpg'
```

The second line of this partial is for setting a default profile image for our
users. If `user.image` isn't set on that user, the URL in the partial will be
returned instead. For the `user` JSON returned for authentication, we keep the
`null` value in the JSON. The authentication JSON should only be visible to
that user, and it's also what the client uses to display the form for editing
the profile. Keeping the `null` image value for authentication makes it so that
the client doesn't need to check if the URL is the default one to let the
user know that they need to set an image, instead an empty field should appear.

{x: create profile template}
Create `app/views/profiles/show.json.jbuilder` with the following code, using
the partial we created in the previous step:

```ruby
json.profile do |json|
  json.partial! 'profiles/profile', user: @user
end
```

## Testing Profiles with Postman

We should be able to get profiles from our backend using the GET Profile
request in Postman. You can change the profile getting requested by changing
the username in the URL of the request. Sending a username that doesn't exist
may appear like an exception in the response, but make sure the status code
returned for that request is 404 and not 500.

{x: test profile postman}
Test the endpoint for getting user profiles using Postman



# Adding Articles CRUD

Now that we can authenticate and retrieve users from our backend, let's build
out the Articles functionality of our application. We'll start out by
generating our Articles model. Articles will need a title, body and description.
We'll be generating a slug for each article which will be used as an identifier
for the client. The slug will be based off of the title, which is downcased and
has all punctuation replaced with dashes.

{x: generate articles model}
Run `rails generate model Article title:string slug:string:uniq body:text description:string favorites_count:integer user:references`

{x: rake db migrate articles}
Run `rake db:migrate` to apply the Article migrations to the database.

{x: add article resources route}
Add `articles` as a resource to `config/routes.rb`

```diff
Rails.application.routes.draw do
  scope :api, defaults: { format: :json } do
    devise_for :users, controllers: { sessions: :sessions },
                       path_names: { sign_in: :login }

    resource :user, only: [:show, :update]

    resources :profiles, param: :username, only: [:show]
+
+   resources :articles, param: :slug, except: [:edit, :new]
  end
end
```

Similar to how we specified `username` as a param for the `profiles` route,
we'll be specifying `slug` as the default parameter for articles, since we'll
be looking up articles by their slug instead of their id.

{x: add validations to articles}
Add the following validations to require titles and bodies for articles in
`app/models/article.rb`

```diff
class Article < ActiveRecord::Base
  belongs_to :user

+ validates :title, presence: true, allow_blank: false
+ validates :body, presence: true, allow_blank: false
end
```

{x: add slug validation to articles}
Add a validation to make sure article slugs are unique and that they can't have
the value of `feed`

```diff
class Article < ActiveRecord::Base
  belongs_to :user

  validates :title, presence: true, allow_blank: false
  validates :body, presence: true, allow_blank: false
+ validates :slug, uniqueness: true, exclusion: { in: ['feed'] }
end
```

The endpoint for retrieving a single article will be `/api/articles/:slug`.
Down the road, we want to create an endpoint for feeds using
`/api/articles/feed`. In order to prevent a possible route collision for that
endpoint, we need to set an `exclusion` validation for articles so that no
article can have a slug of `feed`

{x: before_validation slug callback}
Add the following callback to the `Article` model to generate slugs:

```diff
class Article < ActiveRecord::Base
  belongs_to :user

  validates :title, presence: true,
                    allow_blank: false
  validates :body, presence: true,
                   allow_blank: false
  validates :slug, uniqueness: true,
                   exclusion: { in: ['feed'] }

+ before_validation do
+   self.slug = self.title.to_s.parameterize
+ end
end
```

This callback will be before validations, so that slugs will still be checked
for uniqueness and made sure they're not saved with the value of `feed`.

{x: add authored_by scope}
Add the following `scope` to `Article`:

```diff
class Article < ActiveRecord::Base
  belongs_to :user
+
+ scope :authored_by, ->(username) { where(user: User.where(username: username)) }

  validates :title, presence: true,
                    allow_blank: false
  validates :body, presence: true,
                   allow_blank: false
  validates :slug, uniqueness: true,
                   exclusion: { in: ['feed'] }

  before_validation do
    self.slug = self.title.to_s.parameterize
  end
end
```

The `authored_by` scope will create a method on `Article` that will allow us to
query for Articles based off of the creator's username. Scopes can also be
chained to other ActiveRecord queries, so we have the ability run queries like
`Article.authored_by('jake').where(slug: 'working-at-statefarm')`.  You can
learn more about ActiveRecord scopes and querying at the [Ruby on Rails Guide](http://guides.rubyonrails.org/active_record_querying.html#scopes)

{x: create articles association user}
In our `User` model, add the following line to create the association between users and articles

```diff
  validates :username, uniqueness: true, presence: true, allow_blank: false
+
+ has_many :articles, dependent: :destroy
```

While not in the current scope of this application, the `dependent: :destroy`
option on the association destroys any associated articles when the user it
belongs to is destroyed. Next, let's set up our controllers for articles.

{x: create articles controller}
Create `app/views/controllers/articles_controller.rb` with the following code:


```ruby
class ArticlesController < ApplicationController
  before_action :authenticate_user!
end
```

{x: create articles params}
Create a private method in ArticlesController to whitelist incoming parameters:

```ruby
  private

  def article_params
    params.require(:article).permit(:title, :body, :description)
  end
```

We only want to whitelist parameters that we want users to be able to change,
so values like `slug` `favorites_count` and timestamps are intentionally left
out.

{x: create articles index action}
Create the following `index` action in `ArticlesController` (be sure to put
actions above the `private` keyword)

```ruby
  def index
    @articles = Article.all.includes(:user)

    @articles = @articles.authored_by(params[:author]) if params[:author].present?

    @articles_count = @articles.count

    @articles = @articles.order(created_at: :desc).offset(params[:offset] || 0).limit(params[:limit] || 20)
  end
```

The `includes` call on `Article.all.includes(:user)` eager loads the associated
user (the author) for each article in a single query (in addition to the
original articles query), allowing us to avoid a database lookup for a single
author when iterating over each article. You can read more about eager loading
at the [Ruby on Rails Guide](http://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations).
Additionally, we're limiting our response to 20 articles by default, although
the client has the ability to change that limit and get additional articles
using an `offset` and/or `limit` query parameter. We're also going to be
providing the total number of articles, before the limit/offset is applied,
allowing the client to paginate articles.

{x: create articles create action}
Create the following `create` action in `ArticlesController`

```ruby
  def create
    @article = Article.new(article_params)
    @article.user = current_user

    if @article.save
      render :show
    else
      render json: { errors: @article.errors }, status: :unprocessable_entity
    end
  end
```

The `create`, `show` and `update` actions will all render the same article JSON
response, so we can just create a single view for `show` and render it in our
`create` and `update` actions.

{x: create articles show action}
Create the following `show` action in `ArticlesController`

```ruby
  def show
    @article = Article.find_by_slug!(params[:slug])
  end
```

For the `update` and `destroy` actions, we only want those actions to be
performed by the user who owns the article. We can get the user id of the
author with `@article.user_id`, and we can get the current user's id with
the instance variable `@current_user_id` that we defined in
`ApplicationController`. While we could use `current_user.id`, it would cost
us another trip to the database. `@current_user_id` is the value taken directly
from the JWT. Any time a user isn't allowed to perform an action, we should
send a 403 status code back to the client.

{x: create articles update action}
Create the following `update` action in `ArticlesController`

```ruby
  def update
    @article = Article.find_by_slug!(params[:slug])

    if @article.user_id == @current_user_id
      @article.update_attributes(article_params)

      render :show
    else
      render json: { errors: { article: ['not owned by user'] } }, status: :forbidden
    end
  end
```

{x: create articles destroy action}
Create the following `destroy` action in `ArticlesController`

```ruby
  def destroy
    @article = Article.find_by_slug!(params[:slug])

    if @article.user_id == @current_user_id
      @article.destroy

      render json: {}
    else
      render json: { errors: { article: ['not owned by user'] } }, status: :forbidden
    end
  end
```

Currently, all of our routes within `ArticlesController` require authentication.
Any request that doesn't provide a valid JWT will return a 401 status code back
to the client. We want our `show` and `index` actions to be publically
accessible, so we'll have to provide adjust the way we're using our filter

{x: add except to articles authenticate_user}
Add the following `except` option to the `authenticate_user!` filter

```ruby
class ArticlesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]

...
```

Now that our article model and controller are set up, let's create the views
for rendering JSON for our articles

{x: create articles view folder}
Create a folder named `articles` in `app/views`

{x: create articles jbuilder partial}
Create the following partial in `app/views/articles/_article.json.jbuilder`:

```ruby
json.(article, :title, :slug, :body, :created_at, :updated_at, :description)
json.author article.user, partial: 'profiles/profile', as: :user
```

The articles JSON will include a partial for author's profile. This lets us
keep using one partial for profiles and saves the client another request
to the backend for retrieving an author's profile when viewing an article.

{x: create articles show view}
Create the following template in `app/views/articles/show.json.jbuilder`:

```ruby
json.article do |json|
  json.partial! 'articles/article', article: @article
end
```

{x: create articles index view}
Create the following template in `app/views/articles/index.json.jbuilder`:

```ruby
json.articles do |json|
  json.array! @articles, partial: 'articles/article', as: :article
end

json.articles_count @articles_count
```

## Testing Articles CRUD with Postman

Now we can test our endpoints using Postman. We should be able to create, retrieve,
update and delete articles, along with being able to List all the Articles in
the database. Using the same endpoint to List articles, we can also pass in a
query parameter of `author` to filter posts in our database by authors' usernames

{x: test create article postman}
Create a couple articles using the "Create Article" request in Postman.
Creating an article with the same title should result in an error, so you'll
have to change the values in the body of the request to create additional
articles

{x: test show article postman}
Retrieve the article you just created using the "Single Article by slug"
request in Postman.

{x: test list all articles postman}
Retrieve all articles from the backend using the "All Articles" request in
Postman.

{x: test list author articles postman}
Filter the articles by author using the "Articles by Author" request in Postman.

{x: test destroy article postman}
Delete an article using the "Delete Article" request in Postman.


# Adding Tags to Articles

One advantage to using Rails is the ability to outsource common functionality
to external gems. For tagging, we're going to be using the `acts_as_taggable_on`
Gem, a popular Rails gem that allows us to add Tagging functionality to any
ActiveRecord model.

{x: research acts as taggable on}
Check out the [acts_as_taggable_on Github repository](https://github.com/mbleigh/acts-as-taggable-on)
and review the Usage section in the Readme.

{x: install acts as taggable on migration}
Run the following Rake task to generate the migration for `acts_as_taggable_on`

`rake acts_as_taggable_on_engine:install:migrations`

{x: migrate tags}
Run `rake db:migrate` to apply the migrations we just generated to our database


{x: add acts as taggable to articles}
Add the following line to the Article model to enable tagging for articles

```diff
class Article < ActiveRecord::Base
  belongs_to :user

  scope :authored_by, ->(username) { where(user: User.where(username: username)) }
+
+ acts_as_taggable

  validates :title, presence: true, allow_blank: false
  validates :body, presence: true, allow_blank: false
  validates :slug, uniqueness: true, exclusion: { in: ['feed'] }

  before_validation do
    self.slug = self.title.to_s.parameterize
  end
end

```

`acts_as_taggable` will then provide us with an attribute called `tag_list` on
our articles, which can be written to when we call `update_attributes` as if it
were a plain attribute on articles. We can also query articles using
`Article.tagged_with` and pass in a string or array of strings to get articles
with that tag. We'll need to be sure to update our templates to include the
`tag_list` attribute in our JSON, and update our controllers so we can accept
`tag_list` as a parameter from the client.

{x: add article tag_list to article partial}
Update `app/views/articles/_article.json.jbuilder` to include `tag_list`

```ruby
json.(article, :title, :slug, :body, :created_at, :updated_at, :description, :tag_list)
```

{x: add tag_list to article params}
Update `article_params` in `app/controllers/articles_controller.rb` to include `tag_list`

```ruby
  def article_params
    params.require(:article).permit(:title, :body, :description, tag_list: [])
  end
```

{x: add tag filter articles index}
Add the following line to the `index` action to filter by tags when a `tag`
query parameter exists:

```diff
  def index
    @articles = Article.all.includes(:user)

+   @articles = @articles.tagged_with(params[:tag]) if params[:tag].present?
    @articles = @articles.authored_by(params[:author]) if params[:author].present?

    @articles_count = @articles.count

    @articles = @articles.order(created_at: :desc).offset(params[:offset] || 0).limit(params[:limit] || 20)
  end
```

We now have the ability to create articles with tags, and we can get a list of
articles tagged with a certain tag from our index endpoint. We can also provide
both `author` and `tag` to our articles index endpoint and filter by both
author and tag. Now, let's create an endpoint for retrieving all the tags used
in our application.

{x: create tags resource routes}
In `config/routes.rb`, add a `resources` for tags. We'll only be needing the
`index` action.


```diff
Rails.application.routes.draw do
  scope :api, defaults: { format: :json } do
    devise_for :users, controllers: { sessions: :sessions },
                       path_names: { sign_in: :login }

    resource :user, only: [:show, :update]

    resources :profiles, param: :username, only: [:show]

    resources :articles, param: :slug, except: [:edit, :new]
+
+   resources :tags, only: [:index]
  end
end

```

{x: create tags controller}
Create `app/controllers/tags_controller.rb` with the following code:

```ruby
class TagsController < ApplicationController
  def index
    render json: { tags: Article.tag_counts.most_used.map(&:name) }
  end
end
```

The `tag_counts` method is provided by the `acts_as_taggable_on` gem. It allows
us to query all the tags used by articles, which we can then use the
`most_used` scope also provided by the gem to sort them by `taggings_count`,
which is an attribute on the tag that keeps track of how often they're used.
`map` transforms the array of Tag objects (which include the tag name and tag
counts) to just an array of the tag name strings.

## Testing Tags with Postman

{x: create article with tags postman}
Using the "Create Article" request, modify the body and create a few articles
with different tag sets.

{x: get article with tags postman}
Fetch an article you've created using the "Single Article by slug" request and
make sure `tagList` is included in the response.

{x: get tags}
Using the "All Tags" request in Postman, send a request and make sure the tags
are listed in descending order based off of how often they're used.


# Adding Favorites to Articles

{x: generate favorite model}
Generate the favofite model by running the following command:

`rails generate model Favorite user:references article:references`

{x: migrate favorite creation}
Run `rake db:migrate` to apply the creation of the Favorites table to our database.

{x: add counter cache for favorites}
Update the generated `app/models/favorite.rb` to enable the counter_cache for
articles.

```diff
class Favorite < ActiveRecord::Base
  belongs_to :user
- belongs_to :article
+ belongs_to :article, counter_cache: true
end
```

The `counter_cache` on a `belongs_to` association updates the parent model's
count of the model. This way, instead of calling `@article.favorites.count`
every time we need number of favorites for an article (which runs a COUNT
query), the `favorites_count` integer on each article is incremented and
decremented every time an article is favorited or unfavorited. You can learn
more about `counter_cache` feature of Rails at the [Ruby on Rails guide](http://guides.rubyonrails.org/association_basics.html#counter-cache).

{x: add has_many favorites association article}
Add a has_many assocation on the Article model for favorites.

```diff
class Article < ActiveRecord::Base
  belongs_to :user
+ has_many :favorites, dependent: :destroy

  scope :authored_by, ->(username) { where(user: User.where(username: username)) }
```

The `dependent: :destroy` option passed to `has_many` associations deletes any
associated childrent when a model is destroyed. In our case, when an article
gets destroyed, any favorites for that article will also get destroyed so that
we don't have stale favorites in our database.

{x: add favorited_by scope article}
Add a scope for querying Articles by which username it was favorited by:

```diff
class Article < ActiveRecord::Base
  belongs_to :user
  has_many :favorites, dependent: :destroy

  scope :authored_by, ->(username) { where(user: User.where(username: username)) }
+ scope :favorited_by, -> (username) { joins(:favorites).where(favorites: { user: User.where(username: username) }) }
```

{x: add has_many favorites association user}
Add a `has_many` association for favorites in our user model

```diff
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :articles
+ has_many :favorites, dependent: :destroy
```

{x: create favorite method user}
Create a method on the User model for creating favorites:

```diff
  def generate_jwt
    JWT.encode({ id: self.id,
                 username: self.username,
                 exp: 60.days.from_now.to_i },
               Rails.application.secrets.secret_key_base)
  end

+ def favorite(article)
+   favorites.find_or_create_by(article: article)
+ end
end
```

{x: create unfavorite method user}
Create a method on the User model for removing favorites

```diff
  end

  def favorite(article)
    favorites.find_or_create_by(article: article)
  end

+ def unfavorite(article)
+   favorites.where(article: article).destroy_all
+
+   article.reload
+ end
end
```

The reason we call `reload` on the article is so that we get an up to date
version of the record with the correct `favorites_count` value.

{x: create favorite check}
Create a method for users to check whether or not they've favorited an article

```ruby
  def favorited?(article)
    favorites.find_by(article_id: article.id).present?
  end
```

We should now have all our models set up for favoriting and favoriting and
ready for endpoints to be created.

{x: create favorite route resource}
Create a singular route resource for favorites nested in articles. We'll only
need the `create` and `destroy` actions.

```ruby
    resources :articles, param: :slug, except: [:edit, :new] do
      resource :favorite, only: [:create, :destroy]
    end
```

This should create the following two routes nested under articles:

```
article_favorite POST   /api/articles/:article_slug/favorite(.:format)     favorites#create {:format=>:json}
                 DELETE /api/articles/:article_slug/favorite(.:format)     favorites#destroy {:format=>:json}
```

{x: create favorites_controller}
Create `app/controllers/favorites_controller.rb` with the following code:

```ruby
class FavoritesController < ApplicationController
  before_action :authenticate_user!
end
```

Every request to this controller will require authentication. Since every
request in this controller will also need an Article (we can't have a Favorite
without an associated article) we will need to look for an Article in each of
our requests. The slug of the article will be provided to us as a URL
parameter.

{x: create find_article favorites filter}
Create a filter in `FavoritesController` to look up the Article we're
performing the action on:

```diff
class FavoritesController < ApplicationController
  before_action :authenticate_user!
+ before_action :find_article!
+
+ private
+
+ def find_article!
+   @article = Article.find_by_slug!(params[:article_slug])
+ end
end
```

Next, let's create our actions for creating and destroying favorites. Since
these are action methods, they'll need to go before the `private` keyword.
We'll respond to the with the Article they're performing the action on.

{x: create favorites create action}
Create the action for favoriting articles

```ruby
  def create
    current_user.favorite(@article)

    render 'articles/show'
  end
```

{x: create favorites destroy action}
Create the action for unfavoriting articles

```ruby
  def destroy
    current_user.unfavorite(@article)

    render 'articles/show'
  end
```

The final FavoritesController should look something like this:

```ruby
class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_article!

  def create
    current_user.favorite(@article)

    render 'articles/show'
  end

  def destroy
    current_user.unfavorite(@article)

    render 'articles/show'
  end

  private

  def find_article!
    @article = Article.find_by_slug!(params[:article_slug])
  end
end

```

Now that favoriting is functioning for articles, we'll need to update the JSON
responses for articles so that the client can know if the current user has
favorited the article or not.

{x: update article json for favorites}
Update `app/views/articles/_article.json.jbuilder` with the following code:

```diff
json.(article, :title, :slug, :body, :created_at, :updated_at, :tag_list, :description)
json.author article.user, partial: 'profiles/profile', as: :user
+json.favorited signed_in? ? current_user.favorited?(article) : false
+json.favorites_count article.favorites_count || 0
```

When no JWT is provided (meaning `signed_in?` returns false), we'll return
false for the value of whether or not that user has favorited the article.

Finally, let's update our articles index endpoint to have the ability to filter
by whether or not a username has favorited the article

{x: add favorites filter for articles index}
In `app/controllers/articles_controller.rb`, add the following line:

```diff
  def index
    @articles = Article.all.includes(:user)

    @articles = @articles.tagged_with(params[:tag]) if params[:tag].present?
    @articles = @articles.authored_by(params[:author]) if params[:author].present?
+   @articles = @articles.favorited_by(params[:favorited]) if params[:favorited].present?

    @articles_count = @articles.count

    @articles = @articles.order(created_at: :desc).offset(params[:offset] || 0).limit(params[:limit] || 20)
  end
```

The query parameter `favorited` will be a username that the client will provide
us with.

## Testing Favoriting using Postman

{x: favorite postman}
Favorite an article using the "Favorite Article" request

{x: unfavorite postman}
Unfavorite an article using the "Unfavorite Article" request


# Comments

{x: generate comments model}
Run `rails generate model Comment body:text user:references article:references`

{x: migrate comments creation}
Run `rake db:migrate` to run the migrations we just generated for creating
comments in our database.

{x: add body validation comments}
Add the following validation in `app/models/comment.rb` to require text for comments:

```diff
class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :article
+
+ validates :body, presence: true, allow_blank: false
end
```

{x: add has_many comments association article}
Add a `has_many` association for comments to the article model

```diff
  has_many :favorites, dependent: :destroy
+ has_many :comments, dependent: :destroy
```

{x: add has_many comments association user}
Add a `has_many` association for comments to the user model


```diff
  has_many :favorites, dependent: :destroy
+ has_many :comments, dependent: :destroy
```

{x: create comments route resource}
Create a comments route resource that's nested under articles. We'll only need
the create, index and destroy actions.

```diff
resources :articles, param: :slug, except: [:edit, :new] do
  resource :favorite, only: [:create, :destroy]
+ resources :comments, only: [:create, :index, :destroy]
end
```

{x: create comments controller}
Create `app/controllers/comments_controller.rb` with the following code:

```ruby
class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
end
```

All actions will require authentication except for the `index` route, so that
users who aren't logged in can still see comments. Since comments depend on an
existing article, we'll need to create a filter for retrieving the article
that's getting the comment actions performed on, just like we did with
favorites

{x: create find_article filter comments}
Create a `find_article!` filter for `CommentsController`

```diff
class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
+ before_action :find_article!

+ private

+ def find_article!
+   @article = Article.find_by_slug!(params[:article_slug])
+ end
end
```

{x: create comments param filter}
Create a `comment_params` method for allowing parameters for comments

```diff
  private

+ def comment_params
+   params.require(:comment).permit(:body)
+ end
```

{x: create comments index action}
Create the `index` action for `CommentsController`. We'll be sending all the
comments for the article to the view.

```ruby
  def index
    @comments = @article.comments.order(created_at: :desc)
  end
```


{x: create comments create action}
Create the following `create` action for `CommentsController`:

```ruby
  def create
    @comment = @article.comments.new(comment_params)
    @comment.user = current_user

    render json: { errors: @comment.errors }, status: :unprocessable_entity unless @comment.save
  end
```

{x: create comments destroy action}
Create the following `destroy` action for `CommentsController`:

```ruby
  def destroy
    @comment = @article.comments.find(params[:id])

    if @comment.user_id == @current_user_id
      @comment.destroy
      render json: {}
    else
      render json: { errors: { comment: ['not owned by user'] } }, status: :forbidden
    end
  end
```

We'll need to make sure that the comment being deleted is owned by the current
user, otherwise we should return a 403 back to the client.

{x: create comments view folder}
Create a folder named `comments` in `app/views`

{x: create comments jbuilder partial}
Create the following jbuilder partial in `app/views/comments/_comment.json.jbuilder`

```ruby
json.(comment, :id, :created_at, :updated_at, :body)
json.author comment.user, partial: 'profiles/profile', as: :user
```

We'll need to include the id of the comment in our JSON response so that the
client can specify which comment to delete

{x: create comments create view}
Create the following jbuilder view in `app/views/comments/create.json.jbuilder`

```ruby
json.comment do |json|
  json.partial! 'comments/comment', comment: @comment
end
```

{x: create comments index view}
Create the following jbuilder view in `app/views/comments/index.json.jbuilder`

```ruby
json.comments do |json|
  json.array! @comments, partial: 'comments/comment', as: :comment
end
```

## Testing Comments using Postman

{x: test create comments postman}
Create a comment using the "Create Comment for Article" request in Postman

{x: test listing comments postman}
Retrieve comments for an article using the "All Comments for Article" request
in Postman

{x: test delete comments postman}
Delete a comment using the "Delete Comment for Article" request in Postman


# Following and Feed

{x: generate acts as follower migrations}
Run `rails generate acts_as_follower` to generate the migrations for the
`acts_as_follower` gem

{x: migrate acts as follower}
Run `rake db:migrate` to apply the `acts_as_follower` migrations to the database

{x: add follower to user model}
Add the following lines to  `app/models/user.rb`

```diff
  has_many :comments, dependent: :destroy
+
+ acts_as_follower
+ acts_as_followable

  def generate_jwt
```

This will give our User model the ability to follow other users.
`acts_as_follower` provides us with a `follow` and `stop_following` method
that we can use. For a full list of methods provided to us, check out the
[acts_as_follower usage](https://github.com/tcocca/acts_as_follower#usage).

{x: add follow route resource}
Add the following nested route to `config/routes.rb`

```ruby
  resources :profiles, param: :username, only: [:show] do
    resource :follow, only: [:create, :destroy]
  end
```

We'll only need the `create` and `destroy` actions for following and
unfollowing.

{x: create follows controller}
Create the following controller in `app/controllers/follows_controller.rb`

```ruby
class FollowsController < ApplicationController
  before_action :authenticate_user!
end
```

{x: create follows create action}
Add the following `create` action to `FollowsController`:

```ruby
  def create
    @user = User.find_by_username!(params[:profile_username])

    current_user.follow(@user) if current_user.id != @user.id

    render 'profiles/show'
  end
```

Since we're responding to the request with the user's profile, we can reuse the
`show` view that we used from `ProfilesController`

{x: create follows destroy action}
Add the following `destroy` action to `FollowsController`:

```ruby
  def destroy
    @user = User.find_by_username!(params[:profile_username])

    current_user.stop_following(@user) if current_user.id != @user.id

    render 'profiles/show'
  end
```

{x: add following to profile json}
Add the `following` attribute to `app/views/profiles/_profile.json.jbuilder`

```diff
 json.(user, :username, :bio, :image)
+json.following signed_in? ? current_user.following?(user) : false
```

## Testing Following using Postman

If you haven't already, create a couple more users on the backend so that we
can test out our following/followers functionality

{x: test follow postman}
Follow a user using the "Follow Profile" request in Postman

{x: test unfollow postman}
Unfollow a user using the "Unfollow Profile" request in Postman


## Creating the feed endpoint

{x: add feed route}
Add a route nested under `articles` for getting feed articles

```diff
resources :articles, param: :slug, except: [:edit, :new] do
  resources :comments, only: [:create, :index, :destroy]
  resource :favorite, only: [:create, :destroy]
+ get :feed, on: :collection
end
```

We're just using a plain `get` to define this route, this ties the action
to `ArticlesController` rather than having to create a `FeedsController`.
the `on: :collection` option creates a url without the `:article_slug` url
parameter, so our endpoint for feeds should look like `/api/articles/feed`.

{x: create articles feed action}
Create the following action in `ArticlesController`

```ruby
  def feed
    @articles = Article.includes(:user).where(user: current_user.following_users)

    @articles_count = @articles.count

    @articles = @articles.order(created_at: :desc).offset(params[:offset] || 0).limit(params[:limit] || 20)

    render :index
  end
```

This action is very similar to our `index` action. It renders the same view for
our JSON response (returning multiple articles to the client), but the
`@articles` we're querying for will belong to the users that our current_user
is following.

## Testing the Feed Endpoint using Postman

We should be able to test our feed endpoint now. If you haven't already, make
sure you've created a user who's following another user who has already created
some articles. If you hit the Feed endpoint with Postman, you should see the
articles from the users that your user is following.

{x: ensure following authors}
Make sure your user is following another user who has created some articles

{x: test feed endpoint postman}
Use the "Feed" request in Postman to test the Feed endpoint we created. We
should see the most recent articles from users we're following.

