FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY VietAITravel.sln ./
COPY VietAITravel.Api/VietAITravel.Api.csproj VietAITravel.Api/
RUN dotnet restore VietAITravel.Api/VietAITravel.Api.csproj
COPY . .
RUN dotnet publish VietAITravel.Api/VietAITravel.Api.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "VietAITravel.Api.dll"]
