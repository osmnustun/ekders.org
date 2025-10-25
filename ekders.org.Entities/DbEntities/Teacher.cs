using ekders.org.Entities.Enums;
using System.ComponentModel.DataAnnotations;
namespace ekders.org.Entities.DbEntities;

public class Teacher
{
[Key]
public int TeacherId { get; set; }
public string? Name { get; set; }
public string? Surname { get; set; }
public string? Mail { get; set; }
public string? PhoneNumber { get; set; }
public TeacherType TeacherType { get; set; } = TeacherType.BransOgretmeni;
public TeacherTitle TeacherTitle { get; set; } = TeacherTitle.Ogretmen;
}
