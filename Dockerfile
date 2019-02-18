FROM ubuntu

FROM reactnativecommunity/react-native-android

RUN echo fs.inotify.max_user_watches=524288 | tee -a /etc/sysctl.conf && sysctl -p
