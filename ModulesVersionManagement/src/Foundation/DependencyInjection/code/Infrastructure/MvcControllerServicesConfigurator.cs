using Microsoft.Extensions.DependencyInjection;
using Sitecore.DependencyInjection;

namespace VersionManagement.Foundation.DependencyInjection.Infrastructure
{
    public class MvcControllerServicesConfigurator : IServicesConfigurator
    {
        public void Configure(IServiceCollection serviceCollection)
        {
            serviceCollection.AddMvcControllers("*.Feature.*");
            serviceCollection.AddClassesWithServiceAttribute("*.Feature.*");
            serviceCollection.AddClassesWithServiceAttribute("*.Foundation.*");
        }
    }
}