using System.ComponentModel.DataAnnotations;

namespace TFL.DevOps.Models;

public class OfficeAssignment
{
    [Key]
    public int InstructorID {get;set;}
    
    [StringLength(50)]
    public string? Location {get;set;}

    public Instructor? Instructor {get;set;}
}