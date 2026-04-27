using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TFL.DevOps.Models;

public class Department
{
    public int DepartmentID {get;set;}
    public string? Name {get;set;}
    [DataType(DataType.Currency)]
    [Column(TypeName = "money")]
    public decimal Budget {get;set;}
    public DateTime StartDate {get;set;}
    public int? InstructorID {get;set;}

    public Instructor? Instructor {get;set;}
    public ICollection<Course> Courses {get;set;}
}