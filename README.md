tests
=====

Some tests for flash platform and stage3d

1. Next I iterate over all devices and check if the current one fits our needs:

    <details><summary>Unfold</summary><p>
  
    ```cpp
    bool check_device_suitability(VkPhysicalDevice const physicalDevice, vector<char const *> const & requiredExtensions)
    {
        VkPhysicalDeviceProperties deviceProperties{};
        vkGetPhysicalDeviceProperties(physicalDevice, &deviceProperties); // #a
        
        if (deviceProperties.deviceType != VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) // #b
            return false;
	
        VkPhysicalDeviceFeatures deviceFeatures{};
        vkGetPhysicalDeviceFeatures(physicalDevice, &deviceFeatures); // #c
	
        if (!deviceFeatures.tessellationShader) // #d
            return false;
	
        if (deviceProperties.limits.maxTessellationPatchSize < 16) // #e
            return false;
	
        if (!deviceFeatures.fillModeNonSolid) // #f
            return false;
	
        if (!check_required_device_extensions(physicalDevice, requiredExtensions)) // #g
            return false;
	
        return true;
    }
    ```
    
    1. First I get device properties with `vkGetPhysicalDeviceProperties` call. This function never fails according to specs so no checks here.
    1. One of my test machines have 2 GPUs and I want to use the more powerfull one so I ignore all non discrete adapters (i.e. integrated). But if your laptop have a modern Intel GPU you can remove this check.
    1. Next I get device features. The difference between properties and features is that the former is a general properties which just show the GPU capabilities while the latter can be enabled or disabled per request.
    1. Here I check that a _tesselation feature_ can be enabled for the considered device.
    1. Next I check the size of a patch. Remember that I'm using 16 point patches so I need to be sure the GPU knows how to deal with them. This is a GPU _property_ and it can be requested only if the corresponding _feature_ (`deviceFeatures.tessellationShader`) is supported.
    1. Next feature to check is an ability to draw in wireframe mode.
    1. And the last one thing to do for now is to check if required extensions are supported by the selected device. Remember, earlier I mentioned extensions and we even added some for the instance creation. You can think of instance extensions as global ones, i.e. you turn them on once per application. But device extensions can be turned on, well, per device. One of the examples of such extensions is `VK_KHR_SWAPCHAIN_EXTENSION_NAME` - the extension that is needed for swap chain creation. Since we don't know yet what is it this list of required extensions is empty. But later when we need one we just add the string to the vector. The `check_required_device_extensions` defined so:
        
        <details><summary>Unfold</summary><p>
  
        ```cpp
        bool check_required_device_extensions(VkPhysicalDevice const physicalDevice, vector<char const *> const & requiredExtensions)
        {
            app::helpers::MaybeExtensionProperties mbExtensions{app::helpers::get_physical_device_device_extension_properties(physicalDevice)};
            if(!mbExtensions)
                return false;
	
            vector<VkExtensionProperties> const & availableExtensions{*mbExtensions};
	
            for (char const * element : requiredExtensions)
            {
                if (find_if(begin(availableExtensions), end(availableExtensions), [element](VkExtensionProperties const & extensionProp) { return strcmp(element, extensionProp.extensionName) == 0; }) == end(availableExtensions))
                return false;
            }
	
            return true;
            }
        ```
        
        1. Where the helper function lools like this:
        
            <details><summary>Unfold</summary><p>
  
            ```cpp
            MaybeExtensionProperties get_physical_device_device_extension_properties(VkPhysicalDevice const physicalDevice)
            {
                assert(physicalDevice);
            
                uint32_t extensionCount{0};
                if (vkEnumerateDeviceExtensionProperties(physicalDevice, nullptr, &extensionCount, nullptr) != VK_SUCCESS)
                    return make_unexpected("failed to get physical device extension properties");
            
                vector<VkExtensionProperties> extensions(extensionCount);
                if (vkEnumerateDeviceExtensionProperties(physicalDevice, nullptr, &extensionCount, extensions.data()) != VK_SUCCESS)
                    return make_unexpected("failed to get physical device extension properties");
	
                return extensions;
            }
            ```
        
            Here we see the familiar pattern for obtaining the list of elements of unknown size in Vulkan.
        
            </p></details>
    
        </p></details>
    
    1. Test Test TEst.
    
    </p></details>
    
1. Next I try to get an underlying window surface format - we need to know it since we want to render to that surface and we want our picture to be correct.
