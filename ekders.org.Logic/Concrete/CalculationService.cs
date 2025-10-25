using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using ekders.org.Entities.Enums;
using ekders.org.Logic.Abstract;
using ekders.org.Entities.Models;

namespace ekders.org.Logic.Concrete
{
    public class CalculationService : ICalculationService
    {
        public CalculationResultViewModel Calculate(TeacherProgramViewModel input)
        {
            var now = DateTime.Now;
            var firstDayOfMonth = new DateTime(now.Year, now.Month, 1);
            var daysInMonth = DateTime.DaysInMonth(now.Year, now.Month);

            var weeklySchedule = input.Programs
                .GroupBy(p => p.DayOfWeek)
                .ToDictionary(g => g.Key, g => g.ToDictionary(p => p.ExtraLessonType, p => p.Count));

            var result = new CalculationResultViewModel
            {
                MonthName = firstDayOfMonth.ToString("MMMM", CultureInfo.CreateSpecificCulture("tr-TR")),
                Year = now.Year,
                LessonTypes = Enum.GetNames(typeof(ExtraLessonType)).ToList()
            };
            
            // Add special planning/guidance types to the list if they don't exist
            if (!result.LessonTypes.Contains("HazirlikVePlanlama")) result.LessonTypes.Add("HazirlikVePlanlama");
            if (!result.LessonTypes.Contains("SinifRehberligi")) result.LessonTypes.Add("SinifRehberligi");


            for (int i = 1; i <= daysInMonth; i++)
            {
                var currentDate = new DateTime(now.Year, now.Month, i);
                var dayOfWeek = currentDate.DayOfWeek;

                var dailyDetail = new DailyDetail
                {
                    DayOfMonth = i,
                    DayName = currentDate.ToString("ddd", CultureInfo.CreateSpecificCulture("tr-TR"))
                };

                // Initialize all hours to 0
                foreach (var typeName in result.LessonTypes)
                {
                    dailyDetail.Hours[typeName] = 0;
                }

                // 1. Apply weekly schedule
                if (weeklySchedule.TryGetValue(dayOfWeek, out var lessonsForDay))
                {
                    foreach (var lesson in lessonsForDay)
                    {
                        dailyDetail.Hours[lesson.Key.ToString()] = lesson.Value;
                    }
                }

                // 2. Apply On-Duty Day (Nobet)
                if (input.OnDutyDay.HasValue && input.OnDutyDay.Value == dayOfWeek)
                {
                    dailyDetail.Hours[ExtraLessonType.NobetGorevi.ToString()] = 3;
                }

                // 3. Apply Class Teacher / Club Duty
                if (dayOfWeek == DayOfWeek.Monday)
                {
                    if (input.IsClassTeacher)
                    {
                        dailyDetail.Hours["SinifRehberligi"] = 2;
                    }
                    if (input.IsClubTeacher)
                    {
                        // Assuming club duty also adds 2 hours, can be adjusted.
                        // If both, let's assume it's still 2, not 4.
                        dailyDetail.Hours["SinifRehberligi"] = 2; 
                    }
                }
                
                result.DailyDetails.Add(dailyDetail);
            }
            
            // 4. Apply "Hazırlık ve Planlama" (1 for every 10 hours)
            for (int week = 0; week < 5; week++)
            {
                var weekDays = result.DailyDetails.Where(d => (d.DayOfMonth - 1) / 7 == week).ToList();
                if (!weekDays.Any()) continue;

                var weeklyLessonHours = weekDays.Sum(d => d.Hours.Where(h => h.Key != ExtraLessonType.NobetGorevi.ToString() && h.Key != "SinifRehberligi" && h.Key != "HazirlikVePlanlama").Sum(h => h.Value));
                
                var planningHours = Math.Min(3, weeklyLessonHours / 10);

                if (planningHours > 0)
                {
                    // Add to the first available day of the week (e.g., Monday)
                    var firstDayOfWeek = weekDays.FirstOrDefault();
                    if (firstDayOfWeek != null)
                    {
                        firstDayOfWeek.Hours["HazirlikVePlanlama"] = planningHours;
                    }
                }
            }

            // Calculate totals
            foreach (var typeName in result.LessonTypes)
            {
                result.MonthlyTotal[typeName] = result.DailyDetails.Sum(d => d.Hours.ContainsKey(typeName) ? d.Hours[typeName] : 0);
            }
            result.GrandTotal = result.MonthlyTotal.Values.Sum();

            return result;
        }
    }
}
