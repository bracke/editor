with Ada.Strings.Unbounded;

package Ada_Regexp is

   type Regexp_Status is
     (Compile_Ok,
      Compile_Error,
      Match_Ok,
      No_Match,
      Match_Limit_Exceeded,
      Match_Error);

   type Regexp is record
      Pattern : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Compile_Result is record
      Status     : Regexp_Status := Compile_Ok;
      Expression : Regexp;
   end record;

   type Match_Result is record
      Status : Regexp_Status := No_Match;
      First  : Natural := 0;
      Last   : Natural := 0;
   end record;

   type Match_Options is record
      Case_Sensitive : Boolean := True;
      Whole_Word     : Boolean := False;
      Max_Steps      : Natural := 100_000;
   end record;

   function Compile (Expression : String) return Compile_Result;

   function Find_From
     (Expression : Regexp;
      Text       : String;
      From       : Positive;
      Options    : Match_Options) return Match_Result;

   function Status_Image (Status : Regexp_Status) return String;

end Ada_Regexp;
