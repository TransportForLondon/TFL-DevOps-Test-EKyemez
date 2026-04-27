namespace TFL.DevOps.Models;

public class Student
{
    public int Id {get; set;}
    public string? FirstMidName { get; set; }
    public string? LastName { get; set; }
    public DateTime? EnrollmentDate { get; set; }

    public ICollection<Enrollment> Enrollments { get; set; }

    public int TotalCredits
    {
        get
        {
            var totalCredits = 0;
            foreach(var enrollment in Enrollments)
            {
                totalCredits = (int)enrollment.Course.Credits;
            }

            return totalCredits;
        }
    }
}