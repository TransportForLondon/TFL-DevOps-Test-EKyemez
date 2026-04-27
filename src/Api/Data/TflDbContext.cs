using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using TFL.DevOps.Models;

namespace TFL.DevOps.Api.Data;

public class TflDbContext : DbContext
{
    public TflDbContext (DbContextOptions<TflDbContext> options) : base(options)
    {
    }

    public DbSet<Course> Courses { get; set; }
    public DbSet<Enrollment> Enrollments { get; set; }
    public DbSet<Student> Students { get; set; }
    public DbSet<Department> Departments { get; set; }
    public DbSet<Instructor> Instructors { get; set; }
    public DbSet<OfficeAssignment> OfficeAssignments { get; set; }
    public DbSet<CourseAssignment> CourseAssignments { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<OfficeAssignment>()
            .HasOne(a => a.Instructor)
            .WithOne(a => a.OfficeAssignment)
            .HasForeignKey<Instructor>(i => i.Id);

        modelBuilder.Entity<CourseAssignment>().ToTable(nameof(CourseAssignment))
            .HasOne(ca => ca.Course)
            .WithMany(c => c.CourseAssignments);

        modelBuilder.Entity<CourseAssignment>().ToTable(nameof(CourseAssignment))
            .HasOne(ca => ca.Instructor)
            .WithMany(i => i.CourseAssignments);

        modelBuilder.Entity<CourseAssignment>().ToTable(nameof(CourseAssignment))
            .HasKey(c => new { c.CourseID, c.InstructorID });
    }
}