#!/usr/bin/env sh

#ansible-playbook -i inventory/inv.ini playbook.yml

### homelab
#ansible-playbook --connection=ssh --inventory=inventory/inv.ini -u def --ask-pass --become --ask-become-pass playbook.yml

### phonelab
#ansible-playbook --connection=ssh --inventory=inventory/inv.ini -u vagrant --ask-pass --become --ask-become-pass playbook.yml
ansible-playbook --inventory=inventory/inv.ini --ask-pass --become --ask-become-pass playbook.yml
#ansible-playbook --connection=local --inventory=inventory/inv.ini -u vagrant --ask-pass --become --ask-become-pass playbook.yml
