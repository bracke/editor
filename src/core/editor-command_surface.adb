with Ada.Containers;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Executor;
with Editor.External_Producers;
with Editor.Keybindings;
with Editor.State;

package body Editor.Command_Surface is

   function Trimmed (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

   function Name_Is_Lower_Kebab (Text : String) return Boolean is
   begin
      if Text'Length = 0 then
         return False;
      end if;

      for Ch of Text loop
         if not (Ch in 'a' .. 'z'
                 or else Ch in '0' .. '9'
                 or else Ch = '-'
                 or else Ch = '.')
         then
            return False;
         end if;
      end loop;

      return Text (Text'First) /= '-'
        and then Text (Text'Last) /= '-'
        and then Ada.Strings.Fixed.Index (Text, "--") = 0
        and then Trimmed (Text) = Text;
   end Name_Is_Lower_Kebab;

   function Stable_Ids_Are_Unique return Boolean is
      Seen  : array (Editor.Commands.Command_Id) of Boolean := (others => False);
      Found : Boolean;
      Round : Editor.Commands.Command_Id;
      use type Editor.Commands.Command_Id;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            Id   : constant Editor.Commands.Command_Id :=
              Editor.Commands.Command_At (I);
            Name : constant String := Editor.Commands.Stable_Command_Name (Id);
         begin
            if Editor.Commands.Is_Concrete_Command (Id) then
               if not Name_Is_Lower_Kebab (Name) then
                  return False;
               end if;

               Round := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
               if not Found or else Round /= Id or else Seen (Round) then
                  return False;
               end if;
               Seen (Round) := True;
            end if;
         end;
      end loop;
      return True;
   end Stable_Ids_Are_Unique;

   function Display_Names_Are_Present return Boolean is
      D : Editor.Commands.Command_Descriptor;
      use type Editor.Commands.Command_Visibility;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         D := Editor.Commands.Descriptor (Editor.Commands.Command_At (I));
         if D.Visibility = Editor.Commands.Palette_Command then
            declare
               Name : constant String := To_String (D.Name);
            begin
               if Name'Length = 0 or else Trimmed (Name) /= Name then
                  return False;
               end if;
            end;
         end if;
      end loop;
      return True;
   end Display_Names_Are_Present;

   function Categories_Are_Valid return Boolean is
      D : Editor.Commands.Command_Descriptor;
      use type Editor.Commands.Command_Visibility;
      use type Editor.Commands.Command_Category;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         D := Editor.Commands.Descriptor (Editor.Commands.Command_At (I));
         declare
            Label : constant String := Editor.Commands.Category_Label (D.Category);
         begin
            if Label'Length = 0 or else Trimmed (Label) /= Label then
               return False;
            end if;
         end;

         if D.Visibility = Editor.Commands.Palette_Command
           and then D.Category = Editor.Commands.Internal_Category
         then
            return False;
         end if;
      end loop;
      return True;
   end Categories_Are_Valid;

   function Visibility_Is_Consistent return Boolean is
      Id : Editor.Commands.Command_Id;
      D  : Editor.Commands.Command_Descriptor;
      use type Editor.Commands.Command_Visibility;
      use type Editor.Commands.Command_Category;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         D := Editor.Commands.Descriptor (Id);

         if Editor.Commands.Visible_In_Command_Palette (Id) /=
            (D.Visibility = Editor.Commands.Palette_Command)
         then
            return False;
         end if;

         if Editor.Commands.Is_Internal_Build_Test_Seam_Command (Id)
           and then (D.Visibility /= Editor.Commands.Hidden_Command
                     or else D.Category /= Editor.Commands.Internal_Category)
         then
            return False;
         end if;

      end loop;
      return True;
   end Visibility_Is_Consistent;

   function Bindability_Is_Consistent return Boolean is
      Id : Editor.Commands.Command_Id;
      D  : Editor.Commands.Command_Descriptor;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         D := Editor.Commands.Descriptor (Id);
         if D.Bindable /= Editor.Commands.Is_Bindable_Command (Id) then
            return False;
         end if;

         if Editor.Commands.Is_Internal_Build_Test_Seam_Command (Id)
           and then D.Bindable
         then
            return False;
         end if;

         if Editor.Commands.Is_Public_Build_Command (Id)
           and then D.Bindable
         then
            return False;
         end if;
      end loop;
      return True;
   end Bindability_Is_Consistent;

   function Executor_Coverage_Is_Complete
     (State : Editor.State.State_Type) return Boolean
   is
      pragma Unreferenced (State);
      Id : Editor.Commands.Command_Id;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         if Editor.Commands.Is_Concrete_Command (Id)
           and then not Editor.Commands.Has_Availability_Handler (Id)
         then
            return False;
         end if;
      end loop;
      return True;
   end Executor_Coverage_Is_Complete;

   function Availability_Reasons_Are_Deterministic
     (State : Editor.State.State_Type) return Boolean
   is
      use type Editor.Commands.Command_Availability_Status;
      A : Editor.Commands.Command_Availability;
      B : Editor.Commands.Command_Availability;
      Id : Editor.Commands.Command_Id;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         A := Editor.Executor.Command_Availability (State, Id);
         B := Editor.Executor.Command_Availability (State, Id);

         if A.Status /= B.Status
           or else To_String (A.Reason) /= To_String (B.Reason)
         then
            return False;
         end if;

         if not Editor.Commands.Is_Available (A)
           and then Editor.Commands.Is_Concrete_Command (Id)
           and then To_String (A.Reason)'Length = 0
         then
            return False;
         end if;
      end loop;
      return True;
   end Availability_Reasons_Are_Deterministic;

   function Palette_Projection_Is_Consistent return Boolean is
      Palette : constant Editor.Commands.Command_Descriptor_Vectors.Vector :=
        Editor.Commands.Palette_Commands;
      Seen : array (Editor.Commands.Command_Id) of Boolean := (others => False);
      use type Ada.Containers.Count_Type;
      use type Editor.Commands.Command_Category;
      use type Editor.Commands.Command_Id;
   begin
      if Natural (Palette.Length) /= Editor.Commands.Palette_Command_Count then
         return False;
      end if;

      for D of Palette loop
         if not Editor.Commands.Visible_In_Command_Palette (D.Id)
           or else D.Category = Editor.Commands.Internal_Category
           or else Editor.Commands.Is_Internal_Build_Test_Seam_Command (D.Id)
           or else Seen (D.Id)
         then
            return False;
         end if;
         Seen (D.Id) := True;
      end loop;

      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            Id : constant Editor.Commands.Command_Id := Editor.Commands.Command_At (I);
         begin
            if Editor.Commands.Visible_In_Command_Palette (Id) /= Seen (Id) then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Palette_Projection_Is_Consistent;

   function Keybinding_Targets_Are_Valid return Boolean is
      Result : constant Editor.Keybindings.Keybinding_Validation_Result :=
        Editor.Keybindings.Validate;
      use type Editor.Keybindings.Keybinding_Validation_Status;
   begin
      if Editor.Keybindings.Status (Result) /= Editor.Keybindings.Valid_Keybindings
        or else Editor.Keybindings.Has_Invalid_Command_Targets (Result)
        or else Editor.Keybindings.Has_Duplicate_Chords (Result)
      then
         return False;
      end if;

      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            Id : constant Editor.Commands.Command_Id := Editor.Commands.Command_At (I);
         begin
            if Editor.Keybindings.Binding_Count_For_Command (Id) > 0
              and then not Editor.Commands.Is_Bindable_Command (Id)
            then
               return False;
            end if;

            if (Editor.Commands.Is_Internal_Build_Test_Seam_Command (Id)
                or else Editor.Commands.Is_Public_Build_Command (Id))
              and then Editor.Keybindings.Binding_Count_For_Command (Id) > 0
            then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Keybinding_Targets_Are_Valid;

   function Descriptors_Are_Complete return Boolean is
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            Id : constant Editor.Commands.Command_Id := Editor.Commands.Command_At (I);
         begin
            if not Editor.Commands.Descriptor_Is_Complete (Id) then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Descriptors_Are_Complete;

   function Review_Command_Surface
     (State : Editor.State.State_Type) return Command_Surface_Review
   is
      Manifest : constant Editor.External_Producers.Public_Build_Guardrail_Regression_Manifest :=
        Editor.External_Producers.Build_Public_Build_Guardrail_Regression_Manifest (State);
      Review : Command_Surface_Review;
   begin
      Review.Descriptor_Count := Editor.Commands.Concrete_Command_Count;
      Review.Stable_Ids_Unique := Stable_Ids_Are_Unique;
      Review.Display_Names_Present := Display_Names_Are_Present
        and then Descriptors_Are_Complete;
      Review.Categories_Valid := Categories_Are_Valid;
      Review.Visibility_Consistent := Visibility_Is_Consistent;
      Review.Bindability_Consistent := Bindability_Is_Consistent;
      Review.Executor_Coverage_Complete := Executor_Coverage_Is_Complete (State);
      Review.Availability_Reasons_Stable :=
        Availability_Reasons_Are_Deterministic (State);
      Review.Palette_Projection_Consistent := Palette_Projection_Is_Consistent;
      Review.Discoverability_Metadata_Coherent :=
        Editor.Commands.Command_Discoverability_Coherent;
      Review.Keybinding_Targets_Valid := Keybinding_Targets_Are_Valid;
      Review.Persistence_Clean := Manifest.Persistence_Exclusion_Clean;
      Review.Public_Build_Guardrail_Intact := Manifest.Manifest_Healthy;

      Review.Review_Passed :=
        Review.Descriptor_Count > 0
        and then Review.Stable_Ids_Unique
        and then Review.Display_Names_Present
        and then Review.Categories_Valid
        and then Review.Visibility_Consistent
        and then Review.Bindability_Consistent
        and then Review.Executor_Coverage_Complete
        and then Review.Availability_Reasons_Stable
        and then Review.Palette_Projection_Consistent
        and then Review.Discoverability_Metadata_Coherent
        and then Review.Keybinding_Targets_Valid
        and then Review.Persistence_Clean
        and then Review.Public_Build_Guardrail_Intact;

      return Review;
   end Review_Command_Surface;

   function Assert_Configuration_Command_Surface_Coherent
     (State : Editor.State.State_Type) return Boolean
   is
      Review : constant Command_Surface_Review := Review_Command_Surface (State);
   begin
      return Review.Review_Passed;
   end Assert_Configuration_Command_Surface_Coherent;

   function Build_Command_Surface_Review_Feedback
     (Review : Command_Surface_Review) return String
   is
   begin
      if Review.Review_Passed then
         return "Commands: command surface healthy";
      elsif not Review.Stable_Ids_Unique then
         return "Commands: duplicate command id detected";
      elsif not Review.Display_Names_Present then
         return "Commands: command descriptor incomplete";
      elsif not Review.Categories_Valid then
         return "Commands: invalid command category detected";
      elsif not Review.Bindability_Consistent then
         return "Commands: bindability mismatch detected";
      elsif not Review.Visibility_Consistent then
         return "Commands: visibility mismatch detected";
      elsif not Review.Executor_Coverage_Complete then
         return "Commands: command handling incomplete";
      elsif not Review.Availability_Reasons_Stable then
         return "Commands: availability reason instability detected";
      elsif not Review.Palette_Projection_Consistent then
         return "Commands: command discovery mismatch detected";
      elsif not Review.Discoverability_Metadata_Coherent then
         return "Commands: command discovery details incomplete";
      elsif not Review.Keybinding_Targets_Valid then
         return "Commands: keybinding target invalid";
      elsif not Review.Persistence_Clean then
         return "Commands: command persistence boundary failed";
      elsif not Review.Public_Build_Guardrail_Intact then
         return "Commands: public build guardrail failed";
      else
         return "Commands: command descriptor incomplete";
      end if;
   end Build_Command_Surface_Review_Feedback;

end Editor.Command_Surface;
