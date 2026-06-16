with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Diagnostic_Status_Line is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 181) + B + 113) mod 1_000_000_007;
   end Mix;

   function Source_Slot (Source : Feed_Source) return Natural is
   begin
      case Source is
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression =>
            return 1;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract =>
            return 2;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit =>
            return 3;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation =>
            return 4;
      end case;
   end Source_Slot;

   function Severity_Rank (Severity : Feed_Severity) return Natural is
   begin
      case Severity is
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Error =>
            return 3;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Warning =>
            return 2;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info =>
            return 1;
      end case;
   end Severity_Rank;

   function Contains_Position
     (Item   : Index_Entry;
      Line   : Positive;
      Column : Positive) return Boolean is
   begin
      if Line < Item.Diagnostic.Start_Line or else Line > Item.Diagnostic.End_Line then
         return False;
      end if;

      if Line = Item.Diagnostic.Start_Line and then Column < Item.Diagnostic.Start_Column then
         return False;
      end if;

      if Line = Item.Diagnostic.End_Line and then Column > Item.Diagnostic.End_Column then
         return False;
      end if;

      return True;
   end Contains_Position;

   function On_Line
     (Item  : Index_Entry;
      Line  : Positive) return Boolean is
   begin
      return Line >= Item.Diagnostic.Start_Line and then Line <= Item.Diagnostic.End_Line;
   end On_Line;

   function Is_Better_Nearest
     (Candidate : Diagnostic_Status_Line_Target;
      Current   : Diagnostic_Status_Line_Target;
      Line      : Positive;
      Column    : Positive) return Boolean
   is
      Candidate_After : constant Boolean :=
        Candidate.Start_Line > Line
        or else (Candidate.Start_Line = Line and then Candidate.Start_Column >= Column);
      Current_After : constant Boolean :=
        Current.Start_Line > Line
        or else (Current.Start_Line = Line and then Current.Start_Column >= Column);
   begin
      if not Current.Has_Target then
         return True;
      end if;

      if Candidate_After /= Current_After then
         return Candidate_After;
      end if;

      if Candidate.Start_Line /= Current.Start_Line then
         if Candidate_After then
            return Candidate.Start_Line < Current.Start_Line;
         else
            return Candidate.Start_Line > Current.Start_Line;
         end if;
      end if;

      if Candidate.Start_Column /= Current.Start_Column then
         if Candidate_After then
            return Candidate.Start_Column < Current.Start_Column;
         else
            return Candidate.Start_Column > Current.Start_Column;
         end if;
      end if;

      if Severity_Rank (Candidate.Severity) /= Severity_Rank (Current.Severity) then
         return Severity_Rank (Candidate.Severity) > Severity_Rank (Current.Severity);
      end if;

      return Candidate.Feed_Index < Current.Feed_Index;
   end Is_Better_Nearest;

   function Make_Target (Item : Index_Entry) return Diagnostic_Status_Line_Target is
      Target : Diagnostic_Status_Line_Target;
   begin
      Target.Has_Target := True;
      Target.Index_Id := Item.Id;
      Target.Feed_Index := Item.Feed_Index;
      Target.Diagnostic := Item.Diagnostic;
      Target.Source := Item.Diagnostic.Source;
      Target.Severity := Item.Diagnostic.Severity;
      Target.Token := Item.Diagnostic.Token;
      Target.Node := Item.Diagnostic.Node;
      Target.Start_Line := Item.Diagnostic.Start_Line;
      Target.Start_Column := Item.Diagnostic.Start_Column;
      Target.End_Line := Item.Diagnostic.End_Line;
      Target.End_Column := Item.Diagnostic.End_Column;
      Target.Fingerprint := Mix
        (Natural (Item.Id) + 1,
         Mix (Item.Feed_Index + 1, Item.Diagnostic.Fingerprint + 1));
      return Target;
   end Make_Target;

   function Summary_For
     (Kind     : Diagnostic_Status_Line_Kind;
      Errors   : Natural;
      Warnings : Natural;
      Infos    : Natural;
      Rejected : Natural) return String is
   begin
      case Kind is
         when Diagnostic_Status_Line_Stale =>
            return Natural'Image (Rejected) & " stale semantic diagnostics withheld";
         when Diagnostic_Status_Line_Error =>
            return Natural'Image (Errors) & " errors,"
              & Natural'Image (Warnings) & " warnings,"
              & Natural'Image (Infos) & " infos";
         when Diagnostic_Status_Line_Warning =>
            return Natural'Image (Warnings) & " warnings,"
              & Natural'Image (Infos) & " infos";
         when Diagnostic_Status_Line_Info =>
            return Natural'Image (Infos) & " infos";
         when Diagnostic_Status_Line_Clean =>
            return "No semantic diagnostics";
      end case;
   end Summary_For;

   procedure Clear (Model : in out Diagnostic_Status_Line_Model) is
   begin
      Model.Line_Status := Diagnostic_Status_Line_Current;
      Model.Kind := Diagnostic_Status_Line_Clean;
      Model.Summary := Null_Unbounded_String;
      Model.Total := 0;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Rejected_Total := 0;
      Model.Current_Line_Total := 0;
      Model.Current_Point_Total := 0;
      Model.Expression_Total := 0;
      Model.Generic_Total := 0;
      Model.Cross_Unit_Total := 0;
      Model.Representation_Total := 0;
      Model.Nearest := (others => <>);
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Index  : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
      Line   : Positive := 1;
      Column : Positive := 1) return Diagnostic_Status_Line_Model
   is
      Model : Diagnostic_Status_Line_Model;
   begin
      if Editor.Ada_Semantic_Diagnostic_Index.Rejected_Stale (Index) then
         Model.Line_Status := Diagnostic_Status_Line_Rejected_Stale;
         Model.Kind := Diagnostic_Status_Line_Stale;
         Model.Rejected_Total :=
           Editor.Ada_Semantic_Diagnostic_Index.Rejected_Entry_Count (Index);
         Model.Summary := To_Unbounded_String
           (Summary_For (Model.Kind, 0, 0, 0, Model.Rejected_Total));
         Model.Result_Fingerprint := Mix
           (Editor.Ada_Semantic_Diagnostic_Index.Fingerprint (Index),
            Model.Rejected_Total + 1);
         return Model;
      end if;

      Model.Total := Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Index);
      Model.Error_Total := Editor.Ada_Semantic_Diagnostic_Index.Error_Count (Index);
      Model.Warning_Total := Editor.Ada_Semantic_Diagnostic_Index.Warning_Count (Index);
      Model.Info_Total := Editor.Ada_Semantic_Diagnostic_Index.Info_Count (Index);
      Model.Result_Fingerprint := Editor.Ada_Semantic_Diagnostic_Index.Fingerprint (Index);

      if Model.Error_Total > 0 then
         Model.Kind := Diagnostic_Status_Line_Error;
      elsif Model.Warning_Total > 0 then
         Model.Kind := Diagnostic_Status_Line_Warning;
      elsif Model.Info_Total > 0 then
         Model.Kind := Diagnostic_Status_Line_Info;
      else
         Model.Kind := Diagnostic_Status_Line_Clean;
      end if;

      for Position in 1 .. Model.Total loop
         declare
            Item : constant Index_Entry :=
              Editor.Ada_Semantic_Diagnostic_Index.Entry_At (Index, Position);
            Target : constant Diagnostic_Status_Line_Target := Make_Target (Item);
         begin
            if On_Line (Item, Line) then
               Model.Current_Line_Total := Model.Current_Line_Total + 1;
            end if;

            if Contains_Position (Item, Line, Column) then
               Model.Current_Point_Total := Model.Current_Point_Total + 1;
            end if;

            case Item.Diagnostic.Source is
               when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression =>
                  Model.Expression_Total := Model.Expression_Total + 1;
               when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract =>
                  Model.Generic_Total := Model.Generic_Total + 1;
               when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit =>
                  Model.Cross_Unit_Total := Model.Cross_Unit_Total + 1;
               when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation =>
                  Model.Representation_Total := Model.Representation_Total + 1;
            end case;

            if Is_Better_Nearest (Target, Model.Nearest, Line, Column) then
               Model.Nearest := Target;
            end if;

            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Target.Fingerprint);
            Model.Result_Fingerprint := Mix
              (Model.Result_Fingerprint, Source_Slot (Item.Diagnostic.Source));
         end;
      end loop;

      Model.Summary := To_Unbounded_String
        (Summary_For
           (Model.Kind, Model.Error_Total, Model.Warning_Total,
            Model.Info_Total, Model.Rejected_Total));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Model.Current_Line_Total + 1);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Model.Current_Point_Total + 1);
      return Model;
   end Build;

   function Status
     (Model : Diagnostic_Status_Line_Model) return Diagnostic_Status_Line_Status is
   begin
      return Model.Line_Status;
   end Status;

   function Current (Model : Diagnostic_Status_Line_Model) return Boolean is
   begin
      return Model.Line_Status = Diagnostic_Status_Line_Current;
   end Current;

   function Rejected_Stale (Model : Diagnostic_Status_Line_Model) return Boolean is
   begin
      return Model.Line_Status = Diagnostic_Status_Line_Rejected_Stale;
   end Rejected_Stale;

   function Summary_Kind
     (Model : Diagnostic_Status_Line_Model) return Diagnostic_Status_Line_Kind is
   begin
      return Model.Kind;
   end Summary_Kind;

   function Summary_Text (Model : Diagnostic_Status_Line_Model) return String is
   begin
      return To_String (Model.Summary);
   end Summary_Text;

   function Diagnostic_Count (Model : Diagnostic_Status_Line_Model) return Natural is
   begin
      return Model.Total;
   end Diagnostic_Count;

   function Error_Count (Model : Diagnostic_Status_Line_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Diagnostic_Status_Line_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Diagnostic_Status_Line_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Rejected_Diagnostic_Count
     (Model : Diagnostic_Status_Line_Model) return Natural is
   begin
      return Model.Rejected_Total;
   end Rejected_Diagnostic_Count;

   function Current_Line_Count
     (Model : Diagnostic_Status_Line_Model) return Natural is
   begin
      return Model.Current_Line_Total;
   end Current_Line_Count;

   function Current_Position_Count
     (Model : Diagnostic_Status_Line_Model) return Natural is
   begin
      return Model.Current_Point_Total;
   end Current_Position_Count;

   function Count_Source
     (Model  : Diagnostic_Status_Line_Model;
      Source : Feed_Source) return Natural is
   begin
      case Source is
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression =>
            return Model.Expression_Total;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract =>
            return Model.Generic_Total;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit =>
            return Model.Cross_Unit_Total;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation =>
            return Model.Representation_Total;
      end case;
   end Count_Source;

   function Has_Diagnostics (Model : Diagnostic_Status_Line_Model) return Boolean is
   begin
      return Model.Total > 0;
   end Has_Diagnostics;

   function Has_Errors (Model : Diagnostic_Status_Line_Model) return Boolean is
   begin
      return Model.Error_Total > 0;
   end Has_Errors;

   function Has_Warnings (Model : Diagnostic_Status_Line_Model) return Boolean is
   begin
      return Model.Warning_Total > 0;
   end Has_Warnings;

   function Has_Infos (Model : Diagnostic_Status_Line_Model) return Boolean is
   begin
      return Model.Info_Total > 0;
   end Has_Infos;

   function Nearest_Diagnostic
     (Model : Diagnostic_Status_Line_Model) return Diagnostic_Status_Line_Target is
   begin
      if not Current (Model) then
         return (others => <>);
      end if;

      return Model.Nearest;
   end Nearest_Diagnostic;

   function Has_Target (Target : Diagnostic_Status_Line_Target) return Boolean is
   begin
      return Target.Has_Target;
   end Has_Target;

   function Fingerprint (Model : Diagnostic_Status_Line_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Diagnostic_Status_Line;
