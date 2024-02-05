# Parameters
## SessionHostTemplate
A `string` value that locates the ARM template used to create session hosts. Can be,
- (Recommended) The Resource Id of an Azure Template Spec. The latest version is automatically selected. The FunctionApp should have read access to the template.
- The Resource Id of an Azure Template Spec version. Even if a newer version is available, the Function app will always use the specified version.
- The URL of a json ARM template. This can be any accessible location such as Storage Account or GitHub.