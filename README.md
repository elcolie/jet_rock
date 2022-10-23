# jet_rock

Websocket, Maps, GPS, multi users in the same page.

[![Built with Cookiecutter Django](https://img.shields.io/badge/built%20with-Cookiecutter%20Django-ff69b4.svg?logo=cookiecutter)](https://github.com/cookiecutter/cookiecutter-django/)
[![Black code style](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/ambv/black)

License: MIT

## Settings
1. `local.yml`
2. `production.yml`

## Usecase
1. 4 users open same map
2. They connect to non-authorize web-socket
3. See each other coordinate on the phone

## Variables
1. Phone query GPS each 10 seconds.
2. Maximum devices are 4 phones.

