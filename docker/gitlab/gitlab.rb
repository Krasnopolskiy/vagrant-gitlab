external_url 'http://localhost:8000'

gitlab_rails['db_adapter'] = "postgresql"
gitlab_rails['db_host'] = "gateway"
gitlab_rails['db_port'] = 5432
gitlab_rails['db_username'] = "postgres"
gitlab_rails['db_password'] = "postgres"
gitlab_rails['db_database'] = "gitlab"

gitlab_rails['redis_host'] = "gateway"
gitlab_rails['redis_port'] = 6379
gitlab_rails['redis_password'] = "mypassword"

postgresql['enable'] = false
redis['enable'] = false

gitlab_rails['initial_root_password'] = 'insecure-kPe5qrk*pgr6zjf'
gitlab_rails['initial_root_email'] = 'admin@local'
