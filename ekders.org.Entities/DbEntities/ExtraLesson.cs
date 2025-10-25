using System.ComponentModel.DataAnnotations;
using ekders.org.Entities.Enums;


namespace ekders.org.Entities.DbEntities;
public class ExtraLesson
{
    [Key]
    public int ExtraLessonId { get; set; }
    public Teacher? Teacher { get; set; }
    public ExtraLessonType ExtraLessonType { get; set; }
    public int Count { get; set; }
    public DateOnly Date { get; set; }
    public DayOfWeek DayOfWeek { get; set; }
}
