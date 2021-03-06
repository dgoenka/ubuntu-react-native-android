FROM ubuntu

# set default build arguments
ARG SDK_VERSION=sdk-tools-linux-4333796.zip
ARG ANDROID_BUILD_VERSION=28
ARG ANDROID_TOOLS_VERSION=28.0.3
ARG BUCK_VERSION=2019.01.10.01
ARG NDK_VERSION=17c
ARG WATCHMAN_VERSION=4.9.0

# set default environment variables
ENV JAVA_HOME       /usr/lib/jvm/java-8-oracle
ENV PATH=${PATH}:${JAVA_HOME}
ENV LANG            en_US.UTF-8
ENV LC_ALL          en_US.UTF-8
ENV ADB_INSTALL_TIMEOUT=10
ENV PATH=${PATH}:/opt/buck/bin/
ENV ANDROID_HOME=/opt/android
ENV ANDROID_SDK_HOME=${ANDROID_HOME}
ENV PATH=${PATH}:${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools
ENV ANDROID_NDK=/opt/ndk/android-ndk-r$NDK_VERSION
ENV ANDROID_NDK_HOME=/opt/ndk/android-ndk-r$NDK_VERSION
ENV PATH=${PATH}:${ANDROID_NDK}


# install Oracle Java
RUN apt-get update && \
  apt-get install -y gnupg2 && \
  apt-get install -y --no-install-recommends locales && \
  locale-gen en_US.UTF-8 && \
  apt-get dist-upgrade -y && \
  apt-get --purge remove openjdk* && \
  echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections && \
  echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" > /etc/apt/sources.list.d/webupd8team-java-trusty.list && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886 && \
  apt-get update && \
  apt-get install -y --no-install-recommends oracle-java8-installer oracle-java8-set-default && \
  apt-get clean all

# install system dependencies
RUN apt-get update -qq && apt-get install -qq -y --no-install-recommends \
        apt-transport-https \
        curl \
        build-essential \
        file \
        git \
        gnupg2 \
        openjdk-8-jre \
        python \
        unzip \
    && rm -rf /var/lib/apt/lists/*;

# install nodejs and yarn packages from nodesource and yarn apt sources
RUN echo "deb https://deb.nodesource.com/node_10.x stretch main" > /etc/apt/sources.list.d/nodesource.list \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && apt-get update -qq \
    && apt-get install -qq -y --no-install-recommends nodejs yarn \
    && rm -rf /var/lib/apt/lists/*

# download and unpack NDK
RUN curl -sS https://dl.google.com/android/repository/android-ndk-r$NDK_VERSION-linux-x86_64.zip -o /tmp/ndk.zip \
    && mkdir /opt/ndk \
    && unzip -q -d /opt/ndk /tmp/ndk.zip \
    && rm /tmp/ndk.zip

# download and install buck using debian package
RUN curl -sS -L https://github.com/facebook/buck/releases/download/v${BUCK_VERSION}/buck.${BUCK_VERSION}_all.deb -o /tmp/buck.deb \
    && dpkg -i /tmp/buck.deb \
    && rm /tmp/buck.deb

# Full reference at https://dl.google.com/android/repository/repository2-1.xml
# download and unpack android
RUN curl -sS https://dl.google.com/android/repository/${SDK_VERSION} -o /tmp/sdk.zip \
    && mkdir /opt/android \
    && unzip -q -d /opt/android /tmp/sdk.zip \
    && rm /tmp/sdk.zip


# Add android SDK tools
RUN cd ~ && mkdir ~/.android && echo '### User Sources for Android SDK Manager' > ~/.android/repositories.cfg \
    && yes | sdkmanager --licenses && sdkmanager --update \
    && yes | sdkmanager "platform-tools" \
        "emulator" \
        "platforms;android-$ANDROID_BUILD_VERSION" \
        "build-tools;$ANDROID_TOOLS_VERSION" \
        "add-ons;addon-google_apis-google-23" \
        "system-images;android-19;google_apis;armeabi-v7a" \
        "extras;android;m2repository"
        
# Set file watches
RUN echo fs.inotify.max_user_watches=1048576 | tee -a /etc/sysctl.conf && /sbin/sysctl -p

#  Install python
RUN sudo apt-get update || true  && sudo apt-get install python
