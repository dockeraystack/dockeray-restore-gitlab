# dockeray-restore-gitlab

Docker Compose usage

```
  rst:
    container_name: rst.mydomain.com
    environment:
      - BACKUP_GITLAB_API_ENDPOINT=https://gitlab.com/api/v4/projects/myprojectid/packages/generic
      - BACKUP_GITLAB_ACCESS_TOKEN=mygitlabtoken
      - LATEST=${LATEST}
      - ENVIRONMENT=${ENVIRONMENT}
    image: dockeraystack/dockeray-restore-gitlab:10.7.3-1.1.0
    hostname: rst
    domainname: mydomain.com
    volumes:
      - restore:/data:rw
```
