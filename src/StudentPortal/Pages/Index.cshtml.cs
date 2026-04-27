using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Net.Http;
using TFL.DevOps.Models;
using System.Text.Json.Serialization;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace TFL.DevOps.StudentPortal.Pages;

public class IndexModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;
    private readonly IHttpClientFactory _httpClientFactory;
    //public Student StudentData { get; set; }

    public IndexModel(ILogger<IndexModel> logger, IHttpClientFactory httpClientFactory)
    {
        _logger = logger;
        _httpClientFactory = httpClientFactory;
    }

    public void OnGet()
    {

    }

    public async Task<IActionResult> OnGetStudentAsync(string firstmidname, string lastname)
    {
        if(ModelState.IsValid)
        {
            var client = _httpClientFactory.CreateClient("school.api");
            var response = await client.GetStringAsync("api/Students");

            var studentsArray = JsonNode.Parse(response).AsArray();

            var studentId = 0;
            foreach(var studentNode in studentsArray)
            {
                if(studentNode!["firstMidName"].ToString() == firstmidname && studentNode!["lastName"].ToString() == lastname)
                {
                    int.TryParse(studentNode!["id"].ToString(), out studentId);
                    break;
                }
            }
            
            if(studentId == 0)
                return NotFound();
            
            var student = await client.GetFromJsonAsync<Student>($"api/Students/{studentId}");

            return Partial("~/Pages/Shared/_StudentDataPartial.cshtml", student);
        }
        else
        {
             throw new Exception("Model state not valid");
        }
    }
}
