using Microsoft.EntityFrameworkCore;
using TFL.DevOps.Api.Data;
using Microsoft.Extensions.DependencyInjection;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddApplicationInsightsTelemetry();

// Add services to the container.
builder.Services
    .AddControllers()
    .AddJsonOptions(
        opt => opt.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles
    );

var serverName = builder.Configuration["DatabaseConnection:ServerName"];
var portNumber = builder.Configuration["DatabaseConnection:PortNumber"];
var dbName = builder.Configuration["DatabaseConnection:DatabaseName"];
var userName = builder.Configuration["DatabaseConnection:UserName"];
var password = builder.Configuration["DatabaseConnection:Password"];

var connection = $"Server=tcp:{serverName},{portNumber};Initial Catalog={dbName};Persist Security Info=False;User ID={userName};Password={password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;";

builder.Services.AddDbContext<TflDbContext>(opt =>
    opt.UseSqlServer(connection, sqlOptions => sqlOptions.EnableRetryOnFailure())
);

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.

app.UseSwagger();
app.UseSwaggerUI();

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
