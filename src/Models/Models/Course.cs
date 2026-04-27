using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TFL.DevOps.Models;

public class Course
{
    [DatabaseGenerated(DatabaseGeneratedOption.None)]
    public int CourseId {get;set;}

    [StringLength(50, MinimumLength = 3)]
    public string? Title {get;set;}
    
    [Range(0, 5)]
    public int? Credits {get;set;}
    public int? DepartmentId {get;set;}

    public Department Department {get;set;}
    public ICollection<Enrollment> Enrollments {get;set;}
    public ICollection<CourseAssignment> CourseAssignments {get;set;}
}