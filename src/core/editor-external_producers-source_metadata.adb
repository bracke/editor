with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.External_Producers.Source_Metadata is

   function Producer_Kind_Is_Valid
     (Kind : Editor.External_Producers.External_Producer_Kind) return Boolean
   is
   begin
      case Kind is
         when Build_Diagnostics_Producer | Compiler_Diagnostics_Producer =>
            return True;
         when No_External_Producer =>
            return False;
      end case;
   end Producer_Kind_Is_Valid;

   function Stable_Name
     (Kind : Editor.External_Producers.External_Producer_Kind) return String is
   begin
      case Kind is
         when Build_Diagnostics_Producer =>
            return "external.build-diagnostics";
         when Compiler_Diagnostics_Producer =>
            return "external.compiler-diagnostics";
         when No_External_Producer =>
            return "";
      end case;
   end Stable_Name;

   function Display_Label
     (Kind : Editor.External_Producers.External_Producer_Kind) return String is
   begin
      case Kind is
         when Build_Diagnostics_Producer =>
            return "Build diagnostics";
         when Compiler_Diagnostics_Producer =>
            return "Compiler diagnostics";
         when No_External_Producer =>
            return "";
      end case;
   end Display_Label;

   function Build_External_Producer_Source
     (Kind : Editor.External_Producers.External_Producer_Kind)
      return Editor.External_Producers.External_Producer_Source
   is
   begin
      return
        (Kind          => Kind,
         Stable_Name   => To_Unbounded_String (Stable_Name (Kind)),
         Display_Label => To_Unbounded_String (Display_Label (Kind)));
   end Build_External_Producer_Source;

   function Build_Compiler_Diagnostics_Producer_Source
     return Editor.External_Producers.External_Producer_Source
   is
   begin
      return Build_External_Producer_Source (Compiler_Diagnostics_Producer);
   end Build_Compiler_Diagnostics_Producer_Source;

   function Producer_Source_Is_Valid
     (Producer : Editor.External_Producers.External_Producer_Source)
      return Boolean
   is
   begin
      return Producer_Kind_Is_Valid (Producer.Kind)
        and then To_String (Producer.Stable_Name) = Stable_Name (Producer.Kind)
        and then To_String (Producer.Display_Label) = Display_Label (Producer.Kind);
   end Producer_Source_Is_Valid;

   function Map_External_Producer_To_Diagnostic_Source
     (Producer : Editor.External_Producers.External_Producer_Source)
      return Editor.Feature_Diagnostics.Diagnostic_Source_Kind
   is
   begin
      if not Producer_Source_Is_Valid (Producer) then
         return Editor.Feature_Diagnostics.Unknown_Diagnostic_Source;
      end if;

      case Producer.Kind is
         when Build_Diagnostics_Producer | Compiler_Diagnostics_Producer =>
            return Editor.Feature_Diagnostics.External_Diagnostic_Source;
         when No_External_Producer =>
            return Editor.Feature_Diagnostics.Unknown_Diagnostic_Source;
      end case;
   end Map_External_Producer_To_Diagnostic_Source;

   function Map_Compiler_Severity_To_Diagnostic_Severity
     (Severity : Editor.External_Producers.Compiler_Diagnostic_Severity)
      return Editor.Feature_Diagnostics.Diagnostic_Severity
   is
   begin
      case Severity is
         when Compiler_Info =>
            return Editor.Feature_Diagnostics.Diagnostic_Info;
         when Compiler_Note =>
            return Editor.Feature_Diagnostics.Diagnostic_Note;
         when Compiler_Unknown =>
            return Editor.Feature_Diagnostics.Diagnostic_Unknown;
         when Compiler_Warning =>
            return Editor.Feature_Diagnostics.Diagnostic_Warning;
         when Compiler_Error | Compiler_Fatal =>
            return Editor.Feature_Diagnostics.Diagnostic_Error;
      end case;
   end Map_Compiler_Severity_To_Diagnostic_Severity;

end Editor.External_Producers.Source_Metadata;
