# Docker Multi-arch CI

This repo helps building multi-arch docker images for your Resin.io devices using Travis CI.

Minimal `.travis.yml`:

```yml
services:
  - docker

before_install:
  - git clone https://github.com/oznu/docker-arm-ci.git ~/docker-arm-ci

before_script:
  - export TARGET_IMAGE_TAG=$(if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then if [ "$TRAVIS_BRANCH" = "master" ]; then echo "armhf"; else echo "$TRAVIS_BRANCH-armhf"; fi; else echo ""; fi)

script:
  - ~/docker-arm-ci/run.sh
```

Private data is stored using encrypted variables in Travis CI and can be added via the `travis` cli tool of from the travis-ci.org website.

```
travis env set --private RESIN_API_KEY <resin api key>
travis env set --private RESIN_USERNAME <resin email address>
travis env set --private RESIN_REPO <user@git.resin.io:user/project.git>
travis env set --private DOCKER_USERNAME <docker username>
travis env set --private DOCKER_PASSWORD <docker password>
travis env set --private TARGET_IMAGE <the docker hub image name, without tags>
```

If your passwords contain any special characters they should be escaped. This can be done using the `printf` command:

```
printf '%q' 'your\password'
```

The `RESIN_PRIVATE_KEY` variable should your unencrypted resin ssh private key encoded using base64:

```
travis env set --private RESIN_PRIVATE_KEY $(cat ~/.ssh/resin.io | base64 -i -)
```

The `RESIN_API_KEY` can be generated from the auth-token in your Resin.io preferences panel:

```
curl -H 'Authorization: Bearer AUTH_TOKEN' -X POST https://api.resin.io/application/NNNN/generate-api-key
```
