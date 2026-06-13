with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Diagnostic_Panel_Projection is

   use type Feed_Severity;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 157) + B + 97) mod 1_000_000_007;
   end Mix;

   function Severity_Group
     (Severity : Feed_Severity) return Diagnostic_Panel_Group_Kind is
   begin
      case Severity is
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Error =>
            return Diagnostic_Panel_Group_Error;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Warning =>
            return Diagnostic_Panel_Group_Warning;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info =>
            return Diagnostic_Panel_Group_Info;
      end case;
   end Severity_Group;

   function Severity_Key (Severity : Feed_Severity) return String is
   begin
      case Severity is
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Error =>
            return "error";
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Warning =>
            return "warning";
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info =>
            return "info";
      end case;
   end Severity_Key;

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

   function Row_Fingerprint (Row : Diagnostic_Panel_Row) return Natural is
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Index_Id) + 1);
      H := Mix (H, Row.Feed_Index + 1);
      H := Mix (H, Row.Diagnostic.Fingerprint + 1);
      H := Mix (H, Source_Slot (Row.Source));
      H := Mix (H, Row.Start_Line);
      H := Mix (H, Row.Start_Column);
      H := Mix (H, Row.End_Line);
      H := Mix (H, Row.End_Column);
      return H;
   end Row_Fingerprint;

   function Starts_After
     (Row    : Diagnostic_Panel_Row;
      Line   : Positive;
      Column : Positive) return Boolean is
   begin
      return Row.Start_Line > Line
        or else (Row.Start_Line = Line and then Row.Start_Column >= Column);
   end Starts_After;

   function Earlier
     (Left, Right : Diagnostic_Panel_Row) return Boolean is
   begin
      if not Has_Row (Right) then
         return True;
      end if;

      if Left.Start_Line /= Right.Start_Line then
         return Left.Start_Line < Right.Start_Line;
      end if;

      if Left.Start_Column /= Right.Start_Column then
         return Left.Start_Column < Right.Start_Column;
      end if;

      return Left.Id < Right.Id;
   end Earlier;

   procedure Clear (Model : in out Diagnostic_Panel_Model) is
   begin
      Model.Rows.Clear;
      Model.Panel_Status := Diagnostic_Panel_Current;
      Model.Selected := No_Diagnostic_Panel_Row;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Rejected_Total := 0;
      Model.Expression_Total := 0;
      Model.Generic_Total := 0;
      Model.Cross_Unit_Total := 0;
      Model.Representation_Total := 0;
      Model.Source_Group_Total := 0;
      Model.File_Group_Total := 0;
      Model.Unit_Group_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Index      : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
      File_Label : String := "";
      Unit_Name  : String := "") return Diagnostic_Panel_Model
   is
      Model : Diagnostic_Panel_Model;
      Has_Expression : Boolean := False;
      Has_Generic : Boolean := False;
      Has_Cross_Unit : Boolean := False;
      Has_Representation : Boolean := False;
   begin
      if Editor.Ada_Semantic_Diagnostic_Index.Rejected_Stale (Index) then
         Model.Panel_Status := Diagnostic_Panel_Rejected_Stale;
         Model.Rejected_Total :=
           Editor.Ada_Semantic_Diagnostic_Index.Rejected_Entry_Count (Index);
         Model.Result_Fingerprint :=
           Mix (Editor.Ada_Semantic_Diagnostic_Index.Fingerprint (Index),
                Model.Rejected_Total + 1);
         return Model;
      end if;

      Model.Error_Total := Editor.Ada_Semantic_Diagnostic_Index.Error_Count (Index);
      Model.Warning_Total := Editor.Ada_Semantic_Diagnostic_Index.Warning_Count (Index);
      Model.Info_Total := Editor.Ada_Semantic_Diagnostic_Index.Info_Count (Index);
      Model.File_Group_Total := (if File_Label'Length > 0 then 1 else 0);
      Model.Unit_Group_Total := (if Unit_Name'Length > 0 then 1 else 0);
      Model.Result_Fingerprint := Editor.Ada_Semantic_Diagnostic_Index.Fingerprint (Index);

      for Position in 1 .. Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Index) loop
         declare
            Source_Entry : constant Index_Entry :=
              Editor.Ada_Semantic_Diagnostic_Index.Entry_At (Index, Position);
            Row : Diagnostic_Panel_Row;
         begin
            Row.Id := Diagnostic_Panel_Row_Id (Position);
            Row.Index_Id := Source_Entry.Id;
            Row.Feed_Index := Source_Entry.Feed_Index;
            Row.Diagnostic := Source_Entry.Diagnostic;
            Row.Severity := Source_Entry.Diagnostic.Severity;
            Row.Source := Source_Entry.Diagnostic.Source;
            Row.Token := Source_Entry.Diagnostic.Token;
            Row.Node := Source_Entry.Diagnostic.Node;
            Row.File_Label := To_Unbounded_String (File_Label);
            Row.Unit_Name := To_Unbounded_String (Unit_Name);
            Row.Group_Kind := Severity_Group (Row.Severity);
            Row.Group_Key := To_Unbounded_String (Severity_Key (Row.Severity));
            Row.Start_Line := Source_Entry.Diagnostic.Start_Line;
            Row.Start_Column := Source_Entry.Diagnostic.Start_Column;
            Row.End_Line := Source_Entry.Diagnostic.End_Line;
            Row.End_Column := Source_Entry.Diagnostic.End_Column;
            Row.Fingerprint := Row_Fingerprint (Row);

            case Row.Source is
               when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression =>
                  Model.Expression_Total := Model.Expression_Total + 1;
                  Has_Expression := True;
               when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract =>
                  Model.Generic_Total := Model.Generic_Total + 1;
                  Has_Generic := True;
               when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit =>
                  Model.Cross_Unit_Total := Model.Cross_Unit_Total + 1;
                  Has_Cross_Unit := True;
               when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation =>
                  Model.Representation_Total := Model.Representation_Total + 1;
                  Has_Representation := True;
            end case;

            if Model.Selected = No_Diagnostic_Panel_Row then
               Model.Selected := Row.Id;
            end if;

            Model.Rows.Append (Row);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
         end;
      end loop;

      if Has_Expression then
         Model.Source_Group_Total := Model.Source_Group_Total + 1;
      end if;
      if Has_Generic then
         Model.Source_Group_Total := Model.Source_Group_Total + 1;
      end if;
      if Has_Cross_Unit then
         Model.Source_Group_Total := Model.Source_Group_Total + 1;
      end if;
      if Has_Representation then
         Model.Source_Group_Total := Model.Source_Group_Total + 1;
      end if;

      return Model;
   end Build;

   function Status (Model : Diagnostic_Panel_Model) return Diagnostic_Panel_Status is
   begin
      return Model.Panel_Status;
   end Status;

   function Current (Model : Diagnostic_Panel_Model) return Boolean is
   begin
      return Model.Panel_Status = Diagnostic_Panel_Current;
   end Current;

   function Rejected_Stale (Model : Diagnostic_Panel_Model) return Boolean is
   begin
      return Model.Panel_Status = Diagnostic_Panel_Rejected_Stale;
   end Rejected_Stale;

   function Row_Count (Model : Diagnostic_Panel_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Diagnostic_Panel_Model;
      Index : Positive) return Diagnostic_Panel_Row
   is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function Error_Row_Count (Model : Diagnostic_Panel_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Row_Count;

   function Warning_Row_Count (Model : Diagnostic_Panel_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Row_Count;

   function Info_Row_Count (Model : Diagnostic_Panel_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Row_Count;

   function Rejected_Row_Count (Model : Diagnostic_Panel_Model) return Natural is
   begin
      return Model.Rejected_Total;
   end Rejected_Row_Count;

   function Count_Source
     (Model  : Diagnostic_Panel_Model;
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

   function Source_Group_Count (Model : Diagnostic_Panel_Model) return Natural is
   begin
      return Model.Source_Group_Total;
   end Source_Group_Count;

   function File_Group_Count (Model : Diagnostic_Panel_Model) return Natural is
   begin
      return Model.File_Group_Total;
   end File_Group_Count;

   function Unit_Group_Count (Model : Diagnostic_Panel_Model) return Natural is
   begin
      return Model.Unit_Group_Total;
   end Unit_Group_Count;

   function Selected_Row (Model : Diagnostic_Panel_Model) return Diagnostic_Panel_Row is
   begin
      if not Current (Model) or else Model.Selected = No_Diagnostic_Panel_Row then
         return (others => <>);
      end if;

      for Row of Model.Rows loop
         if Row.Id = Model.Selected then
            return Row;
         end if;
      end loop;

      return (others => <>);
   end Selected_Row;

   function Select_Row
     (Model : Diagnostic_Panel_Model;
      Row   : Diagnostic_Panel_Row_Id) return Diagnostic_Panel_Model
   is
      Result : Diagnostic_Panel_Model := Model;
   begin
      if not Current (Result) then
         Result.Selected := No_Diagnostic_Panel_Row;
         return Result;
      end if;

      for Candidate of Result.Rows loop
         if Candidate.Id = Row then
            Result.Selected := Row;
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Natural (Row) + 1);
            return Result;
         end if;
      end loop;

      Result.Selected := No_Diagnostic_Panel_Row;
      Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, 1);
      return Result;
   end Select_Row;

   function Select_Nearest
     (Model  : Diagnostic_Panel_Model;
      Line   : Positive;
      Column : Positive) return Diagnostic_Panel_Model
   is
      Best : Diagnostic_Panel_Row;
   begin
      if not Current (Model) then
         return Model;
      end if;

      for Row of Model.Rows loop
         if Starts_After (Row, Line, Column) and then Earlier (Row, Best) then
            Best := Row;
         end if;
      end loop;

      if not Has_Row (Best) then
         for Row of Model.Rows loop
            if Earlier (Row, Best) then
               Best := Row;
            end if;
         end loop;
      end if;

      if Has_Row (Best) then
         return Select_Row (Model, Best.Id);
      end if;

      return Model;
   end Select_Nearest;

   function First_Row_For_Severity
     (Model    : Diagnostic_Panel_Model;
      Severity : Feed_Severity) return Diagnostic_Panel_Row
   is
      Best : Diagnostic_Panel_Row;
   begin
      if not Current (Model) then
         return Best;
      end if;

      for Row of Model.Rows loop
         if Row.Severity = Severity and then Earlier (Row, Best) then
            Best := Row;
         end if;
      end loop;
      return Best;
   end First_Row_For_Severity;

   function Has_Row (Row : Diagnostic_Panel_Row) return Boolean is
   begin
      return Row.Id /= No_Diagnostic_Panel_Row;
   end Has_Row;

   function Fingerprint (Model : Diagnostic_Panel_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Diagnostic_Panel_Projection;
