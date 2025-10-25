using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using ekders.org.Entities.Models;
using ekders.org.Entities.DbEntities;
using System.Collections.Generic;
using System;
using ekders.org.Entities.Enums;
using ekders.org.Logic.Abstract;
using ekders.org.Models;

namespace ekders.org.Controllers;

public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;
    private readonly ICalculationService _calculationService;

    public HomeController(ILogger<HomeController> logger, ICalculationService calculationService)
    {
        _logger = logger;
        _calculationService = calculationService;
    }

    [HttpGet]
    public IActionResult Index()
    {
        var model = new TeacherProgramViewModel();
        var days = new[] { DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Wednesday, DayOfWeek.Thursday, DayOfWeek.Friday, DayOfWeek.Saturday, DayOfWeek.Sunday };
        var lessonTypes = new[] {
            ExtraLessonType.Gunduz, ExtraLessonType.Gece, ExtraLessonType.OzelEgitim, ExtraLessonType.Egzersiz,
            ExtraLessonType.DykGunduz, ExtraLessonType.DykGece, ExtraLessonType.IyepGunduz, ExtraLessonType.IyepGece
        };

        foreach (var day in days)
        {
            foreach (var type in lessonTypes)
            {
                model.Programs.Add(new TeacherProgram { DayOfWeek = day, ExtraLessonType = type });
            }
        }
        return View(model);
    }

    [HttpPost]
    public IActionResult Index(TeacherProgramViewModel model)
    {
        var result = _calculationService.Calculate(model);
        model.CalculationResult = result;
        return View(model);
    }

    public IActionResult Privacy()
    {
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
