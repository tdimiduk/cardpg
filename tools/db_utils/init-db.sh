#!/usr/bin/env bash
S="drop database cardpg; drop role cardpg; create database cardpg; create user cardpg password 'cardpg'; grant all on database cardpg to cardpg"
echo "$S" | sudo -u postgres psql
