FROM mcr.microsoft.com/dotnet/sdk:8.0

WORKDIR /mauienv
COPY launch.json .vscode
COPY tasks.json .vscode
# TODO: add .vs-code volume

# set environment variable/path
ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools

# install GtkSharp
RUN git clone https://bgithub.xyz/GtkSharp/GtkSharp.git
WORKDIR /mauienv/GtkSharp
RUN sed -i 's/"8.0.100", "8.0.200"}/"8.0.100", "8.0.200", "8.0.300", "8.0.400"}/g' build.cake  # add missing version bands
RUN dotnet tool restore
  # ^ this allows debugging using the vscode devcontainer extension 
RUN dotnet cake --verbosity=diagnostic --BuildTarget=InstallWorkload
RUN sed -i 's#http://deb.debian.org/debian#https://mirrors.aliyun.com/debian#g' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's#http://deb.debian.org/debian-security#https://mirrors.aliyun.com/debian-security#g' /etc/apt/sources.list.d/debian.sources && \
    apt-get update
RUN apt install -y libgtk-3-dev libgtksourceview-4-0
RUN dotnet new install GtkSharp.Template.CSharp
WORKDIR /mauienv

# ___ Optional Setup with Persistent Volume Share on Local Host __
# if you want to maintain a maui folder locally, mapped as a container volume to persist changes done in the container,
# git clone https://github.com/lytico/maui in the maui-docker folder and make sure it is mounted everytime you run the container, 
# using the docker run -v option or VS Code with devcontainer extension that is provided in this repo. further instructions below:
# 1. uncomment this line:
# RUN echo 'chown -R root:root maui \n cd maui \n dotnet build Microsoft.Maui.BuildTasks.slnf \n dotnet build Microsoft.Maui.Gtk.slnf \n apt clean \n echo "done building maui; now  cd maui/src/Controls/samples/Controls.Sample  and  dotnet run --framework net8.0-gtk"' > build-gtk-platform.sh & chmod a+x build-gtk-platform.sh
# 2. comment out all following commands from "RUN git clone ..." on.
# 3. open a terminal; cd into the maui-docker folder and (re)build the docker image with the command docker build -t maui-env .
# 4 start the container using:
# xhost + & docker run -it --rm -e DISPLAY=$DISPLAY -v "$HOME/maui-docker/maui:/mauienv/maui" -v /tmp/.X11-unix:/tmp/.X11-unix -t maui-env bash
# 5. install an editor like nano or vi to make sure only the <_IncludeGtk> tag in Directory.Build.Override.props.in has the value 'true' (<_IncludeGtk>true</_IncludeGtk>)
# 6. inside the container start ./build-gtk-platform.sh
# finally, if needed, again disable the local display using xhost -

# ___ Read-Only Setup with MAUI Build Already as Part of the Container Image __
RUN git clone https://bgithub.xyz/lytico/maui
WORKDIR /mauienv/maui


# # Overrides Begins++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
RUN rm NuGet.config
# # make sure to only include Gtk platform using sed
# # ( see also https://github.com/lytico/maui/blob/6ef7f0c066808ea0d4142812ef4d956245e6a711/.github/workflows/build-gtk.yml#L34-L36 )
RUN sed -i 's/_IncludeGtk></_IncludeGtk>true</g' Directory.Build.Override.props.in
RUN sed -i 's/_IncludeWindows>true</_IncludeWindows>false</g' Directory.Build.Override.props.in
RUN sed -i 's/_IncludeTizen>true</_IncludeTizen>false</g' Directory.Build.Override.props.in
RUN sed -i 's/_IncludeAndroid>true</_IncludeAndroid>false</g' Directory.Build.Override.props.in
RUN sed -i 's/_IncludeIos>true</_IncludeIos>false</g' Directory.Build.Override.props.in
RUN sed -i 's/_IncludeMacCatalyst>true</_IncludeMacCatalyst>false</g' Directory.Build.Override.props.in
RUN sed -i 's/_IncludeMacOS>true</_IncludeMacOS>false</g' Directory.Build.Override.props.in
RUN sed -i 's/_IncludeGtk></_IncludeGtk>true</g' Directory.Build.Override.props
RUN sed -i 's/_IncludeWindows>true</_IncludeWindows>false</g' Directory.Build.Override.props
RUN sed -i 's/_IncludeTizen>true</_IncludeTizen>false</g' Directory.Build.Override.props
RUN sed -i 's/_IncludeAndroid>true</_IncludeAndroid>false</g' Directory.Build.Override.props
RUN sed -i 's/_IncludeIos>true</_IncludeIos>false</g' Directory.Build.Override.props
RUN sed -i 's/_IncludeMacCatalyst>true</_IncludeMacCatalyst>false</g' Directory.Build.Override.props
RUN sed -i 's/_IncludeMacOS>true</_IncludeMacOS>false</g' Directory.Build.Override.props
# # Overrides Ends------------------------------------------------------------------------------------------------------------------------
RUN dotnet build Microsoft.Maui.BuildTasks.slnf
RUN dotnet build Microsoft.Maui.Gtk.slnf
RUN apt clean
WORKDIR /mauienv/maui/src/Controls/samples/Controls.Sample
# on the local terminal type:
# xhost + & docker run -it --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -t maui-env dotnet run --framework net8.0-gtk & xhost -
# alternatively, you could omit the xhost commands and attach a VS Code instance to the container and run it there.
