# API Spec

### Authentication Header:

`Authorization: Token jwt.token.here`

## JSON Objects returned by API:

### Users (for authentication)

```
{
  "user": {
    "username": "jake",
    "email": "jake@jake.jake",
    "token": "jwt.token.here"
  }
}
```

### Profile

```
{
  "profile": {
    "username": "jake",
    "bio": "I work at statefarm",
    "image": "https://i.stack.imgur.com/xHWG8.jpg",
    "following": false
  }
}
```

### Single Article

```
{
  "article": {
    "slug": "how-to-train-your-dragon",
    "title": "How to train your dragon",
    "description": "Ever wonder how?",
    "body": "It takes a Jacobian",
    "created_at": "2016-02-18T03:22:56.637Z",
    "updated_at": "2016-02-18T03:48:35.824Z"
  }
}
```

### Multiple Articles

```
{
  "articles":[{
    "description": "Ever wonder how?",
    "slug": "how-to-train-your-dragon",
    "title": "How to train your dragon",
    "created_at": "2016-02-18T03:22:56.637Z",
    "updated_at": "2016-02-18T03:48:35.824Z"
  }, {
    "description": "So toothless",
    "slug": "how-to-train-your-dragon-2",
    "title": "How to train your dragon 2",
    "created_at": "2016-02-18T03:22:56.637Z",
    "updated_at": "2016-02-18T03:48:35.824Z"
  }]
}
```

### Single comment

```
{
  "comment": {
    "body": "It takes a Jacobian",
    "created_at": "2016-02-18T03:22:56.637Z",
    "author_username": "jake"
  }
}
```

### Multiple comments

```
{
  "comments": [{
    "body": "It takes a Jacobian",
    "created_at": "2016-02-18T03:22:56.637Z",
    "author_username": "jake"
  }]
}
```


## Endpoints:

### Authentication:

`POST /api/users/sign_in`

Request body:
```
{
  "user":{
    "email": "jake@jake.jake",
    "password": "jakejake"
  }
}
```
No authentication required, returns a User object



### Registration:

`POST /api/users`

Request body:
```
{
  "user":{
    "email": "jake@jake.jake",
    "password": "jakejake"
  }
}
```

No authentication required, returns a User object



### Get Profile

`GET /api/profiles/:username`

Authentication optional, returns a profile object



### Update profile

`PUT /api/users`

Authentication required

Request body:
```
{
  "user":{
    "email": "jake@jake.jake",
    "bio": "I like to skateboard",
    "image": "https://i.stack.imgur.com/xHWG8.jpg"
  }
}
```



### Follow user

`POST /api/profiles/:username/follow`

Authentication required, returns profile object



### Unfollow user

`DELETE /api/profiles/:username/follow`

Authentication required, returns profile object



### List Articles

`GET /api/articles`

Authentication optional, will return array of articles most recent first

Use to get all articles globally, provide tag or author query param to filter

Query Parameters:

Filter by tag:
`?tag=AngularJS`

Filter by author:
`?author=jake`



### Feed articles

`GET /api/feed`

Authentication required, will return array of articles more recent first created by followed users



### Create Article

`POST /api/articles`

```
{
  "article": {
    "title": "How to train your dragon",
    "description": "Ever wonder how?",
    "body": "You have to believe"
  }
}
```

Authentication required, will return article object



### Update article

`PUT /api/articles/:slug`

```
{
  "article": {
    "title": "Did you train your dragon?"
  }
}
```

Authentication required, will return article object



### Adding comments to an article

`POST /api/articles/:article_slug/comments`

```
{
  "comment": {
    "body": "His name was my name too."
  }
}
```

Authentication required, returns the created comment object



### Getting comments to an article

`GET /api/articles/:article_slug/comments`

Authentication optional, returns multiple comments
