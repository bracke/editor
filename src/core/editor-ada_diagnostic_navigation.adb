package body Editor.Ada_Diagnostic_Navigation is

   use type Feed_Severity;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 149) + B + 83) mod 1_000_000_007;
   end Mix;

   function Starts_After
     (Target : Diagnostic_Navigation_Target;
      Line   : Positive;
      Column : Positive) return Boolean is
   begin
      return Target.Start_Line > Line
        or else (Target.Start_Line = Line and then Target.Start_Column > Column);
   end Starts_After;

   function Starts_Before
     (Target : Diagnostic_Navigation_Target;
      Line   : Positive;
      Column : Positive) return Boolean is
   begin
      return Target.Start_Line < Line
        or else (Target.Start_Line = Line and then Target.Start_Column < Column);
   end Starts_Before;

   function Earlier
     (Left, Right : Diagnostic_Navigation_Target) return Boolean is
   begin
      if not Has_Target (Right) then
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

   function Later
     (Left, Right : Diagnostic_Navigation_Target) return Boolean is
   begin
      if not Has_Target (Right) then
         return True;
      end if;

      if Left.Start_Line /= Right.Start_Line then
         return Left.Start_Line > Right.Start_Line;
      end if;

      if Left.Start_Column /= Right.Start_Column then
         return Left.Start_Column > Right.Start_Column;
      end if;

      return Left.Id > Right.Id;
   end Later;

   function Target_Fingerprint
     (Target : Diagnostic_Navigation_Target) return Natural
   is
      H : Natural := Natural (Target.Id);
   begin
      H := Mix (H, Natural (Target.Index_Id) + 1);
      H := Mix (H, Target.Feed_Index + 1);
      H := Mix (H, Target.Diagnostic.Fingerprint + 1);
      H := Mix (H, Target.Start_Line);
      H := Mix (H, Target.Start_Column);
      H := Mix (H, Target.End_Line);
      H := Mix (H, Target.End_Column);
      return H;
   end Target_Fingerprint;

   procedure Clear (Model : in out Diagnostic_Navigation_Model) is
   begin
      Model.Targets.Clear;
      Model.Navigation_Status := Diagnostic_Navigation_Current;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Rejected_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model)
      return Diagnostic_Navigation_Model
   is
      Model : Diagnostic_Navigation_Model;
   begin
      if Editor.Ada_Semantic_Diagnostic_Index.Rejected_Stale (Index) then
         Model.Navigation_Status := Diagnostic_Navigation_Rejected_Stale;
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
      Model.Result_Fingerprint := Editor.Ada_Semantic_Diagnostic_Index.Fingerprint (Index);

      for Position in 1 .. Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Index) loop
         declare
            Source : constant Index_Entry :=
              Editor.Ada_Semantic_Diagnostic_Index.Entry_At (Index, Position);
            Target : Diagnostic_Navigation_Target;
         begin
            Target.Id := Diagnostic_Navigation_Target_Id (Position);
            Target.Index_Id := Source.Id;
            Target.Feed_Index := Source.Feed_Index;
            Target.Diagnostic := Source.Diagnostic;
            Target.Source := Source.Diagnostic.Source;
            Target.Severity := Source.Diagnostic.Severity;
            Target.Token := Source.Diagnostic.Token;
            Target.Node := Source.Diagnostic.Node;
            Target.Start_Line := Source.Diagnostic.Start_Line;
            Target.Start_Column := Source.Diagnostic.Start_Column;
            Target.End_Line := Source.Diagnostic.End_Line;
            Target.End_Column := Source.Diagnostic.End_Column;
            Target.Fingerprint := Target_Fingerprint (Target);
            Model.Targets.Append (Target);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Target.Fingerprint);
         end;
      end loop;

      return Model;
   end Build;

   function Status (Model : Diagnostic_Navigation_Model) return Diagnostic_Navigation_Status is
   begin
      return Model.Navigation_Status;
   end Status;

   function Current (Model : Diagnostic_Navigation_Model) return Boolean is
   begin
      return Model.Navigation_Status = Diagnostic_Navigation_Current;
   end Current;

   function Rejected_Stale (Model : Diagnostic_Navigation_Model) return Boolean is
   begin
      return Model.Navigation_Status = Diagnostic_Navigation_Rejected_Stale;
   end Rejected_Stale;

   function Navigation_Target_Count (Model : Diagnostic_Navigation_Model) return Natural is
   begin
      return Natural (Model.Targets.Length);
   end Navigation_Target_Count;

   function Target_At
     (Model : Diagnostic_Navigation_Model;
      Index : Positive) return Diagnostic_Navigation_Target
   is
   begin
      if Index > Natural (Model.Targets.Length) then
         return (others => <>);
      end if;
      return Model.Targets.Element (Index);
   end Target_At;

   function Error_Target_Count (Model : Diagnostic_Navigation_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Target_Count;

   function Warning_Target_Count (Model : Diagnostic_Navigation_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Target_Count;

   function Info_Target_Count (Model : Diagnostic_Navigation_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Target_Count;

   function Rejected_Target_Count (Model : Diagnostic_Navigation_Model) return Natural is
   begin
      return Model.Rejected_Total;
   end Rejected_Target_Count;

   function Fingerprint (Model : Diagnostic_Navigation_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function First_Diagnostic
     (Model : Diagnostic_Navigation_Model) return Diagnostic_Navigation_Target
   is
      Best : Diagnostic_Navigation_Target;
   begin
      if not Current (Model) then
         return Best;
      end if;

      for Target of Model.Targets loop
         if Earlier (Target, Best) then
            Best := Target;
         end if;
      end loop;
      return Best;
   end First_Diagnostic;

   function Last_Diagnostic
     (Model : Diagnostic_Navigation_Model) return Diagnostic_Navigation_Target
   is
      Best : Diagnostic_Navigation_Target;
   begin
      if not Current (Model) then
         return Best;
      end if;

      for Target of Model.Targets loop
         if Later (Target, Best) then
            Best := Target;
         end if;
      end loop;
      return Best;
   end Last_Diagnostic;

   function First_Diagnostic
     (Model    : Diagnostic_Navigation_Model;
      Severity : Feed_Severity) return Diagnostic_Navigation_Target
   is
      Best : Diagnostic_Navigation_Target;
   begin
      if not Current (Model) then
         return Best;
      end if;

      for Target of Model.Targets loop
         if Target.Severity = Severity and then Earlier (Target, Best) then
            Best := Target;
         end if;
      end loop;
      return Best;
   end First_Diagnostic;

   function Last_Diagnostic
     (Model    : Diagnostic_Navigation_Model;
      Severity : Feed_Severity) return Diagnostic_Navigation_Target
   is
      Best : Diagnostic_Navigation_Target;
   begin
      if not Current (Model) then
         return Best;
      end if;

      for Target of Model.Targets loop
         if Target.Severity = Severity and then Later (Target, Best) then
            Best := Target;
         end if;
      end loop;
      return Best;
   end Last_Diagnostic;

   function Next_Diagnostic
     (Model  : Diagnostic_Navigation_Model;
      Line   : Positive;
      Column : Positive) return Diagnostic_Navigation_Target
   is
      Best : Diagnostic_Navigation_Target;
   begin
      if not Current (Model) then
         return Best;
      end if;

      for Target of Model.Targets loop
         if Starts_After (Target, Line, Column) and then Earlier (Target, Best) then
            Best := Target;
         end if;
      end loop;
      return Best;
   end Next_Diagnostic;

   function Previous_Diagnostic
     (Model  : Diagnostic_Navigation_Model;
      Line   : Positive;
      Column : Positive) return Diagnostic_Navigation_Target
   is
      Best : Diagnostic_Navigation_Target;
   begin
      if not Current (Model) then
         return Best;
      end if;

      for Target of Model.Targets loop
         if Starts_Before (Target, Line, Column) and then Later (Target, Best) then
            Best := Target;
         end if;
      end loop;
      return Best;
   end Previous_Diagnostic;

   function Next_Diagnostic
     (Model    : Diagnostic_Navigation_Model;
      Line     : Positive;
      Column   : Positive;
      Severity : Feed_Severity) return Diagnostic_Navigation_Target
   is
      Best : Diagnostic_Navigation_Target;
   begin
      if not Current (Model) then
         return Best;
      end if;

      for Target of Model.Targets loop
         if Target.Severity = Severity
           and then Starts_After (Target, Line, Column)
           and then Earlier (Target, Best)
         then
            Best := Target;
         end if;
      end loop;
      return Best;
   end Next_Diagnostic;

   function Previous_Diagnostic
     (Model    : Diagnostic_Navigation_Model;
      Line     : Positive;
      Column   : Positive;
      Severity : Feed_Severity) return Diagnostic_Navigation_Target
   is
      Best : Diagnostic_Navigation_Target;
   begin
      if not Current (Model) then
         return Best;
      end if;

      for Target of Model.Targets loop
         if Target.Severity = Severity
           and then Starts_Before (Target, Line, Column)
           and then Later (Target, Best)
         then
            Best := Target;
         end if;
      end loop;
      return Best;
   end Previous_Diagnostic;

   function Has_Target (Target : Diagnostic_Navigation_Target) return Boolean is
   begin
      return Target.Id /= No_Diagnostic_Navigation_Target;
   end Has_Target;

end Editor.Ada_Diagnostic_Navigation;
