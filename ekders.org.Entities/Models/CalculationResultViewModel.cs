using System.Collections.Generic;
using System.Linq;

namespace ekders.org.Entities.Models
{
    public class DailyDetail
    {
        public int DayOfMonth { get; set; }
        public string DayName { get; set; }
        public Dictionary<string, int> Hours { get; set; } = new Dictionary<string, int>();
        public int TotalHours => Hours.Values.Sum();
    }

    public class CalculationResultViewModel
    {
        public string MonthName { get; set; }
        public int Year { get; set; }
        public List<string> LessonTypes { get; set; } = new List<string>();
        public List<DailyDetail> DailyDetails { get; set; } = new List<DailyDetail>();
        public Dictionary<string, int> MonthlyTotal { get; set; } = new Dictionary<string, int>();
        public int GrandTotal { get; set; }
    }
}
