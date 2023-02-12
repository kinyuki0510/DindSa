FROM rockylinux:9 AS base
EXPOSE 80
EXPOSE 443
WORKDIR /root

RUN dnf install -y findutils sudo wget procps procps-ng

COPY dotnet/dotnet-install.sh dotnet-install.sh
COPY dotnet/after-install.sh after-install.sh
RUN chmod +x dotnet-install.sh && \
    bash ./dotnet-install.sh -c 6.0 --install-dir /usr/share/dotnet --runtime aspnetcore && \
    chmod +x after-install.sh && \
    bash ./after-install.sh && \
    echo 'export PATH=$PATH:$DOTNET_ROOT' | tee -a ~/.bashrc && \
    echo 'export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools' >> ~/.bashrc

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

COPY *.sln .
COPY **/*.csproj .
RUN dotnet sln list | grep ".csproj" \
    | while read -r line; do \ 
        mkdir -p $(dirname $line); \
        mv $(basename $line) $(dirname $line); \
      done;
RUN ls -alrt

COPY Directory.Build.props ./
RUN dotnet restore "DindSa.sln" -p:RestoreUseSkipNonexistentTargets=false
COPY . .

FROM build AS publish
RUN dotnet publish "DindSa.sln" -c Release -o /app/publish

FROM base AS final
COPY --from=publish /app/publish /app
WORKDIR /app

RUN echo root:safsafas | chpasswd

ARG USERNAME=kuser
ARG USERPASSWD=kpass
ARG GROUPNAME=kgroup
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID $GROUPNAME && \
    useradd -m -s /bin/bash -u $UID -g $GID $USERNAME && \
    echo ${USERNAME}:${USERPASSWD} | chpasswd

RUN cd /app && \
    mkdir -p config && chown $USERNAME:$GROUPNAME config && \
    mkdir -p log && chown $USERNAME:$GROUPNAME log && \
    mkdir -p queue && chown $USERNAME:$GROUPNAME queue && \
    mkdir -p temporary && chown $USERNAME:$GROUPNAME temporary

USER $USERNAME
RUN whoami

ENTRYPOINT ["dotnet", "ConsoleApp.dll"]
