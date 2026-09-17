#!/usr/bin/bash

cp ./gs-bootc-helper /usr/libexec/gs-bootc-helper
chmod 755 /usr/libexec/gs-bootc-helper
chown root:root /usr/libexec/gs-bootc-helper
cp ./99-bootc-check.rules /usr/share/polkit-1/rules.d/
chmod 644 /usr/share/polkit-1/rules.d/99-bootc-check.rules
chown root:root /usr/share/polkit-1/rules.d/99-bootc-check.rules
cp ./org.containers.bootc.policy /usr/share/polkit-1/actions/
chmod 644 /usr/share/polkit-1/actions/org.containers.bootc.policy
chown root:root /usr/share/polkit-1/actions/org.containers.bootc.policy