with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Stream_Attribute_Profile_Conformance is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Language_Model.Representation_Clause_Kind;

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (Left) * 16_777_619) xor
        (Hash_Value (Right) + 536_870_909);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Normalize (Name : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Ada.Strings.Fixed.Trim (Name, Ada.Strings.Both));
   end Normalize;

   function Stream_Attribute
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind in Editor.Ada_Language_Model.Representation_Read_Clause |
                     Editor.Ada_Language_Model.Representation_Write_Clause |
                     Editor.Ada_Language_Model.Representation_Input_Clause |
                     Editor.Ada_Language_Model.Representation_Output_Clause |
                     Editor.Ada_Language_Model.Representation_Put_Image_Clause;
   end Stream_Attribute;

   function Needs_Function
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind = Editor.Ada_Language_Model.Representation_Input_Clause;
   end Needs_Function;

   function Expected_Arity
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Natural is
   begin
      case Kind is
         when Editor.Ada_Language_Model.Representation_Input_Clause =>
            return 1;
         when Editor.Ada_Language_Model.Representation_Read_Clause |
              Editor.Ada_Language_Model.Representation_Write_Clause |
              Editor.Ada_Language_Model.Representation_Output_Clause |
              Editor.Ada_Language_Model.Representation_Put_Image_Clause =>
            return 2;
         when others =>
            return 0;
      end case;
   end Expected_Arity;

   function Subtype_Matches_Target
     (Result_Subtype : String;
      Target         : String) return Boolean is
      R : constant String := Normalize (Result_Subtype);
      T : constant String := Normalize (Target);
   begin
      return R = T or else R = "" or else T = "";
   end Subtype_Matches_Target;

   procedure Clear (Model : in out Stream_Profile_Conformance_Model) is
   begin
      Model.Checks.Clear;
      Model.Status_Counts := (others => 0);
      Model.Compatible_Total := 0;
      Model.Target_Error_Total := 0;
      Model.Missing_Total := 0;
      Model.Ambiguous_Total := 0;
      Model.Arity_Mismatch_Total := 0;
      Model.Result_Mismatch_Total := 0;
      Model.Mode_Mismatch_Total := 0;
      Model.Unknown_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Count_Result
     (Model : in out Stream_Profile_Conformance_Model;
      Info  : Stream_Profile_Conformance_Info) is
   begin
      Model.Status_Counts (Info.Status) := Model.Status_Counts (Info.Status) + 1;
      case Info.Status is
         when Stream_Profile_Conformance_Compatible =>
            Model.Compatible_Total := Model.Compatible_Total + 1;
         when Stream_Profile_Conformance_Target_Error =>
            Model.Target_Error_Total := Model.Target_Error_Total + 1;
         when Stream_Profile_Conformance_Handler_Missing =>
            Model.Missing_Total := Model.Missing_Total + 1;
         when Stream_Profile_Conformance_Handler_Ambiguous =>
            Model.Ambiguous_Total := Model.Ambiguous_Total + 1;
         when Stream_Profile_Conformance_Arity_Mismatch =>
            Model.Arity_Mismatch_Total := Model.Arity_Mismatch_Total + 1;
         when Stream_Profile_Conformance_Result_Mismatch =>
            Model.Result_Mismatch_Total := Model.Result_Mismatch_Total + 1;
         when Stream_Profile_Conformance_Mode_Requires_Procedure |
              Stream_Profile_Conformance_Mode_Requires_Function =>
            Model.Mode_Mismatch_Total := Model.Mode_Mismatch_Total + 1;
         when Stream_Profile_Conformance_Profile_Unknown |
              Stream_Profile_Conformance_Handler_Malformed |
              Stream_Profile_Conformance_Unknown =>
            Model.Unknown_Total := Model.Unknown_Total + 1;
         when Stream_Profile_Conformance_Not_Stream_Attribute =>
            null;
      end case;
   end Count_Result;

   procedure Append_Check
     (Model : in out Stream_Profile_Conformance_Model;
      Info  : Stream_Profile_Conformance_Info) is
      Item : Stream_Profile_Conformance_Info := Info;
   begin
      Item.Fingerprint :=
        Mix (Natural (Item.Clause_Node),
             Mix (Item.Source_Line,
                  Mix (Editor.Ada_Language_Model.Representation_Clause_Kind'Pos (Item.Attribute_Kind),
                       Mix (Natural (Item.Callable_Profile),
                            Mix (Item.Parameter_Count,
                                 Mix (Item.Candidate_Count,
                                      Mix (Item.Source_Fingerprint,
                                           Stream_Profile_Conformance_Status'Pos (Item.Status))))))));
      Model.Checks.Append (Item);
      Count_Result (Model, Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Fingerprint);
   end Append_Check;

   function Match_Profile
     (Profiles : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Handler  : String;
      Count    : out Natural) return Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info
   is
      Normalized : constant String := Normalize (Handler);
      Result : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info;
   begin
      Count := 0;
      for Index in 1 .. Editor.Ada_Call_Profile_Shapes.Callable_Profile_Count (Profiles) loop
         declare
            Candidate : constant Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info :=
              Editor.Ada_Call_Profile_Shapes.Callable_Profile_At (Profiles, Index);
         begin
            if To_String (Candidate.Normalized_Name) = Normalized then
               Count := Count + 1;
               if Count = 1 then
                  Result := Candidate;
               end if;
            end if;
         end;
      end loop;
      return Result;
   end Match_Profile;

   function Build
     (Legality : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Profiles : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model)
      return Stream_Profile_Conformance_Model
   is
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
      use type Editor.Ada_Representation_Legality.Stream_Subprogram_Status;
      Result : Stream_Profile_Conformance_Model;
   begin
      for Index in 1 .. Editor.Ada_Representation_Legality.Check_Count (Legality) loop
         declare
            Clause : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
              Editor.Ada_Representation_Legality.Check_At (Legality, Index);
            Info : Stream_Profile_Conformance_Info;
            Candidate_Count : Natural := 0;
            Profile : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info;
         begin
            Info.Clause_Node := Clause.Clause_Node;
            Info.Target_Name := Clause.Target_Name;
            Info.Normalized_Target := Clause.Normalized_Target;
            Info.Attribute_Kind := Clause.Clause_Kind;
            Info.Handler_Name := Clause.Stream_Designator;
            Info.Normalized_Handler := To_Unbounded_String (Normalize (To_String (Clause.Stream_Designator)));
            Info.Source_Line := Clause.Source_Line;
            Info.Source_Fingerprint := Clause.Fingerprint;

            if not Stream_Attribute (Clause.Clause_Kind) then
               Info.Status := Stream_Profile_Conformance_Not_Stream_Attribute;
            elsif Clause.Status = Editor.Ada_Representation_Legality.Representation_Legality_Stream_Target_Incompatible then
               Info.Status := Stream_Profile_Conformance_Target_Error;
            elsif Clause.Stream_Status in
              Editor.Ada_Representation_Legality.Stream_Subprogram_Malformed |
              Editor.Ada_Representation_Legality.Stream_Subprogram_Unknown
            then
               Info.Status := Stream_Profile_Conformance_Handler_Malformed;
            elsif To_String (Clause.Stream_Designator) = "" then
               Info.Status := Stream_Profile_Conformance_Handler_Missing;
            else
               Profile := Match_Profile (Profiles, To_String (Clause.Stream_Designator), Candidate_Count);
               Info.Candidate_Count := Candidate_Count;
               if Candidate_Count = 0 then
                  Info.Status := Stream_Profile_Conformance_Profile_Unknown;
               elsif Candidate_Count > 1 then
                  Info.Callable_Profile := Profile.Id;
                  Info.Status := Stream_Profile_Conformance_Handler_Ambiguous;
               else
                  Info.Callable_Profile := Profile.Id;
                  Info.Parameter_Count := Profile.Parameter_Count;
                  Info.Result_Subtype := Profile.Result_Subtype;
                  if Needs_Function (Clause.Clause_Kind) and then not Profile.Has_Result then
                     Info.Status := Stream_Profile_Conformance_Mode_Requires_Function;
                  elsif not Needs_Function (Clause.Clause_Kind) and then Profile.Has_Result then
                     Info.Status := Stream_Profile_Conformance_Mode_Requires_Procedure;
                  elsif Profile.Parameter_Count /= Expected_Arity (Clause.Clause_Kind) then
                     Info.Status := Stream_Profile_Conformance_Arity_Mismatch;
                  elsif Needs_Function (Clause.Clause_Kind)
                    and then not Subtype_Matches_Target
                      (To_String (Profile.Result_Subtype), To_String (Clause.Normalized_Target))
                  then
                     Info.Status := Stream_Profile_Conformance_Result_Mismatch;
                  else
                     Info.Status := Stream_Profile_Conformance_Compatible;
                  end if;
               end if;
            end if;

            Append_Check (Result, Info);
         end;
      end loop;
      return Result;
   end Build;

   function Check_Count (Model : Stream_Profile_Conformance_Model) return Natural is
   begin
      return Natural (Model.Checks.Length);
   end Check_Count;

   function Check_At
     (Model : Stream_Profile_Conformance_Model;
      Index : Positive) return Stream_Profile_Conformance_Info is
   begin
      if Index > Natural (Model.Checks.Length) then
         return (others => <>);
      end if;
      return Model.Checks (Index);
   end Check_At;

   function First_For_Target
     (Model  : Stream_Profile_Conformance_Model;
      Target : String) return Stream_Profile_Conformance_Info is
      Normalized : constant String := Normalize (Target);
   begin
      for Item of Model.Checks loop
         if To_String (Item.Normalized_Target) = Normalized then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Target;

   function First_For_Handler
     (Model   : Stream_Profile_Conformance_Model;
      Handler : String) return Stream_Profile_Conformance_Info is
      Normalized : constant String := Normalize (Handler);
   begin
      for Item of Model.Checks loop
         if To_String (Item.Normalized_Handler) = Normalized then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Handler;

   function Count_Status
     (Model  : Stream_Profile_Conformance_Model;
      Status : Stream_Profile_Conformance_Status) return Natural is
   begin
      return Model.Status_Counts (Status);
   end Count_Status;

   function Compatible_Count (Model : Stream_Profile_Conformance_Model) return Natural is
   begin
      return Model.Compatible_Total;
   end Compatible_Count;

   function Target_Error_Count (Model : Stream_Profile_Conformance_Model) return Natural is
   begin
      return Model.Target_Error_Total;
   end Target_Error_Count;

   function Missing_Handler_Count (Model : Stream_Profile_Conformance_Model) return Natural is
   begin
      return Model.Missing_Total;
   end Missing_Handler_Count;

   function Ambiguous_Handler_Count (Model : Stream_Profile_Conformance_Model) return Natural is
   begin
      return Model.Ambiguous_Total;
   end Ambiguous_Handler_Count;

   function Arity_Mismatch_Count (Model : Stream_Profile_Conformance_Model) return Natural is
   begin
      return Model.Arity_Mismatch_Total;
   end Arity_Mismatch_Count;

   function Result_Mismatch_Count (Model : Stream_Profile_Conformance_Model) return Natural is
   begin
      return Model.Result_Mismatch_Total;
   end Result_Mismatch_Count;

   function Mode_Mismatch_Count (Model : Stream_Profile_Conformance_Model) return Natural is
   begin
      return Model.Mode_Mismatch_Total;
   end Mode_Mismatch_Count;

   function Unknown_Count (Model : Stream_Profile_Conformance_Model) return Natural is
   begin
      return Model.Unknown_Total;
   end Unknown_Count;

   function Fingerprint (Model : Stream_Profile_Conformance_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Stream_Attribute_Profile_Conformance;
