FROM debian:buster-slim

# docker build -t pop3-server .
# docker run -d -p 110:110 -p 587:587 --name pop3-server pop3-server

# Install necessary packages
RUN apt-get update && \
    apt-get install -y dovecot-pop3d dovecot-imapd postfix && \
    apt-get clean

# Create vmail user and group
RUN groupadd -g 5000 vmail && \
    useradd -g vmail -u 5000 vmail -d /var/mail

# Copy configuration files
COPY config/dovecot.conf /etc/dovecot/dovecot.conf
COPY config/users /etc/dovecot/users
COPY config/main.cf /etc/postfix/main.cf
COPY config/vmailbox /etc/postfix/vmailbox

# Set permissions for Dovecot user file and mail directory
RUN chown vmail:dovecot /etc/dovecot/users && \
    chmod 640 /etc/dovecot/users && \
    mkdir -p /var/mail/vhosts/star-co.net.kp/test/{cur,new,tmp} && \
    chown -R vmail:vmail /var/mail/vhosts && \
    chmod -R 700 /var/mail/vhosts

# Ensure Maildir structure exists before creating fake email
RUN mkdir -p /var/mail/vhosts/star-co.net.kp/test/new && \
    echo -e "Return-Path: <test@test.com>\nDelivered-To: test@star-co.net.kp\nReceived: from localhost (localhost [127.0.0.1])\n    by 137.184.53.156 (Postfix) with ESMTP id ABC12345678\n    for <test@star-co.net.kp>; Thu, 1 Sep 2024 00:00:00 +0000 (UTC)\nSubject: Test Email\nFrom: test@test.com\nTo: test@star-co.net.kp\nDate: Thu, 1 Sep 2024 00:00:00 +0000\n\nThis is a test email for test@star-co.net.kp." > /var/mail/vhosts/star-co.net.kp/test/new/1000000000.M123456P1234.localhost && \
    chown vmail:vmail /var/mail/vhosts/star-co.net.kp/test/new/1000000000.M123456P1234.localhost && \
    chmod 600 /var/mail/vhosts/star-co.net.kp/test/new/1000000000.M123456P1234.localhost

# Create Dovecot log file and set permissions
RUN mkdir -p /var/log && \
    touch /var/log/dovecot.log && \
    chown dovecot:dovecot /var/log/dovecot.log && \
    chmod 640 /var/log/dovecot.log

# Set the hostname for Postfix
RUN echo "star-co.net.kp" > /etc/hostname

# Expose ports for POP3 and SMTP
EXPOSE 110 587

# Start services and keep the container running
CMD service postfix start && service dovecot start && tail -f /var/log/dovecot.log
