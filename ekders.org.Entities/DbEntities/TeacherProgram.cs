using System;
using ekders.org.Entities.Enums;

namespace ekders.org.Entities.DbEntities;

public class TeacherProgram
{
    public int TeacherProgramId { get; set; }
    public Teacher? Teacher { get; set; }
    public ExtraLessonType ExtraLessonType { get; set; }
    public DayOfWeek DayOfWeek { get; set; }
    public DateOnly Date { get; set; }
    public int Count { get; set; }
    public bool IsClassTeacher { get; set; }
    public bool IsClubTeacher { get; set; }


}
