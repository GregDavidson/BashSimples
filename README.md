# Directory: /Shared/Lib/Bash **or** ~/Lib/Bash

Here are some Bash scripts I developed for NGender partners.

## Profiles

| Profile Script	| Purpose
|-----------------------|--------
| .bash_profile		| sourced at login time by bash
| .bashrc		| sourced by non-login shell, sets up simples system if it exists, enhances an interactive shell

## Simples System

Simples/		a system to manage shell extension modules

| Simples Command	| Purpose
|-----------------------|--------
| simple_require *module_name*	| loads given module name if not present
| simple_source *module_name*	| loads given module name unconditionally
| Simples/Bin/*			| scripts to test simples modules
