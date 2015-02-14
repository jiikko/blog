server {
  listen 80;
  server_name blog.jiikko.com;

  access_log on;
  access_log  /var/log/nginx/access-blog.log;
  error_log /var/log/nginx/error-blog.log;

  location ~ ^/(assets|images|javascripts|stylesheets|swfs|system)/ {
    expires     max;
    add_header  Cache-Control public;
    access_log on;
    access_log  /var/log/nginx/access.log;
    break;
  }

  location / {
    passenger_enabled on;
    root /var/www/blog.jiikko.com/current/public;

    if (-f $request_filename) {
      expires 24h;
      access_log off;
      break;
    }
  }
}
