using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using ekders.org.Models;

namespace ekders.org.Controllers;

public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;

    public HomeController(ILogger<HomeController> logger)
    {
        _logger = logger;
    }

    [HttpGet]
    public IActionResult Index()
    {
        // Initialize with default values, maybe from a config file or database later
        var model = new Ekders
        {
            GelirVergisiOrani = 0.15, // Default to 15%
            DamgaVergisiOrani = 0.00759 // Default to 0.759%
        };
        return View(model);
    }

    [HttpPost]
    public IActionResult Index(Ekders model)
    {
        // Maaş Katsayısı (This should be configurable, using a recent value)
        const double maasKatsayisi = 1.012556;

        // Ek Ders Göstergeleri
        const int gunduzGosterge = 140;
        const int geceGosterge = 150;

        // Toplam Gösterge Puanı
        double toplamGosterge =
            (model.NormalGunduz * gunduzGosterge) +
            (model.NormalGece * geceGosterge) +
            (model.YuzdeYirmibesGunduz * gunduzGosterge * 1.25) +
            (model.YuzdeYirmibesGece * geceGosterge * 1.25);
           

        // Hesaplamalar
        model.BrutUcret = toplamGosterge * maasKatsayisi;
        double gelirVergisi = model.BrutUcret * model.GelirVergisiOrani/100;
        double damgaVergisi = model.BrutUcret * model.DamgaVergisiOrani/10000;
        model.NetUcret = model.BrutUcret - gelirVergisi - damgaVergisi;

        // Pass the calculated model back to the view
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
