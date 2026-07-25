with Ada.Strings.Unbounded;
with Editor.Feature_Diagnostics;
with Editor.External_Producers;
with Editor.External_Producers.Diagnostics;

package Editor.External_Producers.Source_Metadata is

   function Producer_Kind_Is_Valid
     (Kind : Editor.External_Producers.Diagnostics.Producer_Kind) return Boolean;

   function Stable_Name
     (Kind : Editor.External_Producers.Diagnostics.Producer_Kind) return String;

   function Display_Label
     (Kind : Editor.External_Producers.Diagnostics.Producer_Kind) return String;

   function Build_External_Producer_Source
     (Kind : Editor.External_Producers.Diagnostics.Producer_Kind)
      return Editor.External_Producers.Diagnostics.Producer_Source;

   function Build_Compiler_Diagnostics_Producer_Source
     return Editor.External_Producers.Diagnostics.Producer_Source;

   function Producer_Source_Is_Valid
     (Producer : Editor.External_Producers.Diagnostics.Producer_Source)
      return Boolean;

   function Map_External_Producer_To_Diagnostic_Source
     (Producer : Editor.External_Producers.Diagnostics.Producer_Source)
      return Editor.Feature_Diagnostics.Diagnostic_Source_Kind;

   function Map_Compiler_Severity_To_Diagnostic_Severity
     (Severity : Editor.External_Producers.Diagnostics.Compiler_Severity)
      return Editor.Feature_Diagnostics.Diagnostic_Severity;

end Editor.External_Producers.Source_Metadata;
