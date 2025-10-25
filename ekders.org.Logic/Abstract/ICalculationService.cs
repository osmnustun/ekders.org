using ekders.org.Entities.Models;

namespace ekders.org.Logic.Abstract
{
    public interface ICalculationService
    {
        CalculationResultViewModel Calculate(TeacherProgramViewModel input);
    }
}

