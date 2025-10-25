using System.Collections.Generic;
using ekders.org.Entities.DbEntities;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace ekders.org.Entities.Models
{
    public class TeacherProgramViewModel
    {
        public List<TeacherProgram> Programs { get; set; }
        public bool IsClassTeacher { get; set; }
        public bool IsClubTeacher { get; set; }
        public DayOfWeek? OnDutyDay { get; set; }
        public CalculationResultViewModel? CalculationResult { get; set; }

        public List<SelectListItem> DaysOfWeek { get; } = new List<SelectListItem>
        {
            new SelectListItem { Value = "", Text = "Nöbet Günü Seçin" },
            new SelectListItem { Value = DayOfWeek.Monday.ToString(), Text = "Pazartesi" },
            new SelectListItem { Value = DayOfWeek.Tuesday.ToString(), Text = "Salı" },
            new SelectListItem { Value = DayOfWeek.Wednesday.ToString(), Text = "Çarşamba" },
            new SelectListItem { Value = DayOfWeek.Thursday.ToString(), Text = "Perşembe" },
            new SelectListItem { Value = DayOfWeek.Friday.ToString(), Text = "Cuma" },
            new SelectListItem { Value = DayOfWeek.Saturday.ToString(), Text = "Cumartesi" },
            new SelectListItem { Value = DayOfWeek.Sunday.ToString(), Text = "Pazar" }
        };

        public TeacherProgramViewModel()
        {
            Programs = new List<TeacherProgram>();
        }
    }
}
