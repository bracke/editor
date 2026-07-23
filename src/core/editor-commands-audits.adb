with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Commands.Audits is

   function Trimmed
     (Text : String) return String
   is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

   function Is_Placeholder_Label
     (Text : String) return Boolean
   is
      T : constant String := Trimmed (Text);
   begin
      return T = "TODO"
        or else T = "Command"
        or else T = "Unnamed";
   end Is_Placeholder_Label;

   function Has_Stable_User_Label
     (Id : Command_Id) return Boolean
   is
      D : constant Command_Descriptor := Descriptor (Id);
      L : constant String := To_String (D.Name);
   begin
      return Id /= No_Command
        and then D.Id = Id
        and then L'Length > 0
        and then Trimmed (L) = L
        and then not Is_Placeholder_Label (L);
   end Has_Stable_User_Label;

   function Has_Command_Reference
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Save_File
            | Command_Save_File_As
            | Command_Close_Active_Buffer
            | Command_Reopen_Closed_Buffer
            | Command_Reload_Active_Buffer
            | Command_Revert_Active_Buffer
            | Command_Rename_Buffer_File
            | Command_Delete_Buffer_File
            | Command_Copy_Buffer_File
            | Command_Move_Buffer_File =>
            null;
         when others =>
            return False;
      end case;

      return Is_File_Lifecycle_Command (Id)
        and then Command_Family (Id) = File_Lifecycle_Family
        and then Command_Effect_Classification (Id) /= No_Command_Effect
        and then Command_Summary (Id)'Length > 0
        and then Command_Availability_Summary (Id)'Length > 0
        and then Command_Mutation_Summary (Id)'Length > 0
        and then Command_Filesystem_Effect_Summary (Id)'Length > 0
        and then Command_State_Preservation_Summary (Id)'Length > 0
        and then Command_Non_Goal_Summary (Id)'Length > 0;
   end Has_Command_Reference;

   function File_Lifecycle_Command_Reference_Coherent return Boolean
   is
      Covered : constant array (Positive range 1 .. 10) of Command_Id :=
        (Command_Save_File,
         Command_Save_File_As,
         Command_Close_Active_Buffer,
         Command_Reopen_Closed_Buffer,
         Command_Reload_Active_Buffer,
         Command_Revert_Active_Buffer,
         Command_Rename_Buffer_File,
         Command_Delete_Buffer_File,
         Command_Copy_Buffer_File,
         Command_Move_Buffer_File);
      Seen : array (Command_Effect_Classification_Id) of Boolean :=
        (others => False);
      D : Command_Descriptor;
   begin
      for Id of Covered loop
         D := Descriptor (Id);
         if D.Id /= Id
           or else D.Category /= File_Category
           or else D.Family /= File_Lifecycle_Family
           or else D.Effect_Classification /= Command_Effect_Classification (Id)
           or else not Has_Command_Reference (Id)
           or else To_String (D.Summary) /= Command_Summary (Id)
           or else To_String (D.Availability_Summary) /= Command_Availability_Summary (Id)
           or else To_String (D.Mutation_Summary) /= Command_Mutation_Summary (Id)
           or else To_String (D.Filesystem_Effect_Summary) /= Command_Filesystem_Effect_Summary (Id)
           or else To_String (D.State_Preservation_Summary) /= Command_State_Preservation_Summary (Id)
           or else To_String (D.Non_Goal_Summary) /= Command_Non_Goal_Summary (Id)
         then
            return False;
         end if;

         if Seen (D.Effect_Classification) then
            return False;
         end if;
         Seen (D.Effect_Classification) := True;
      end loop;

      return True;
   end File_Lifecycle_Command_Reference_Coherent;

   function Has_Discoverability_Metadata
     (Id : Command_Id) return Boolean
   is
      D : constant Command_Descriptor := Descriptor (Id);
      Stable : constant String := Stable_Command_Name (Id);
      Title : constant String := To_String (D.Name);
      Description_Text : constant String := To_String (D.Description);
      Category_Text : constant String := Discoverability_Category_Label (Id);
      Class_Text : constant String := Classification_Label (Id);
   begin
      if not Is_Concrete_Command (Id) then
         return False;
      end if;

      if D.Id /= Id then
         return False;
      end if;

      if Stable'Length = 0
        or else Ada.Strings.Fixed.Trim (Stable, Ada.Strings.Both) /= Stable
      then
         return False;
      end if;

      if D.Visibility = Hidden_Command then
         return not Visible_In_Command_Palette (Id);
      end if;

      if Title'Length = 0
        or else Ada.Strings.Fixed.Trim (Title, Ada.Strings.Both) /= Title
        or else Description_Text'Length = 0
        or else Ada.Strings.Fixed.Trim (Description_Text, Ada.Strings.Both) /= Description_Text
        or else Category_Text'Length = 0
        or else Ada.Strings.Fixed.Trim (Category_Text, Ada.Strings.Both) /= Category_Text
        or else Class_Text'Length = 0
        or else Ada.Strings.Fixed.Trim (Class_Text, Ada.Strings.Both) /= Class_Text
      then
         return False;
      end if;

      if D.Category = Internal_Category then
         return False;
      end if;

      return True;
   end Has_Discoverability_Metadata;

   function Command_Discoverability_Coherent return Boolean
   is
   begin
      for Id in Command_Id loop
         if Is_Concrete_Command (Id) then
            if not Has_Discoverability_Metadata (Id) then
               return False;
            end if;

            if Is_Internal_Command (Id) and then Visible_In_Command_Palette (Id) then
               return False;
            end if;
         end if;
      end loop;

      return True;
   end Command_Discoverability_Coherent;

   function Descriptor_Is_Complete
     (Id : Command_Id) return Boolean
   is
      D : constant Command_Descriptor := Descriptor (Id);
      L : constant String := To_String (D.Name);
      Desc : constant String := To_String (D.Description);
      Cat_Label : constant String := Category_Label (D.Category);
   begin
      if D.Id /= Id then
         return False;
      end if;

      if Id = No_Command then
         return D.Visibility = Hidden_Command
           and then D.Category = Internal_Category;
      end if;

      if not Has_Stable_User_Label (Id) then
         return False;
      end if;

      if Cat_Label'Length = 0 or else Trimmed (Cat_Label) /= Cat_Label then
         return False;
      end if;

      if Desc'Length = 0 or else Trimmed (Desc) /= Desc then
         return False;
      end if;

      if D.Visibility = Palette_Command then
         return D.Category /= Internal_Category;
      end if;

      return True;
   end Descriptor_Is_Complete;

   procedure Audit_Command
     (Id      : Command_Id;
      Failure : out Command_Audit_Failure;
      Found   : out Boolean)
   is
      D    : constant Command_Descriptor := Descriptor (Id);
      Desc : constant String := To_String (D.Description);
   begin
      Failure := (Kind => Missing_Descriptor, Command => Id);
      Found := False;

      if not Is_Concrete_Command (Id) then
         return;
      end if;

      if not Has_Descriptor (Id) then
         Failure := (Kind => Missing_Descriptor, Command => Id);
         Found := True;
         return;
      end if;

      if not Has_Stable_User_Label (Id) then
         Failure := (Kind => Missing_Label, Command => Id);
         Found := True;
         return;
      end if;

      if Desc'Length = 0
        or else Trimmed (Desc) /= Desc
      then
         Failure := (Kind => Missing_Description, Command => Id);
         Found := True;
         return;
      end if;

      if Category_Label (D.Category)'Length = 0 then
         Failure := (Kind => Missing_Category, Command => Id);
         Found := True;
         return;
      end if;

      if Is_Bindable_Command (Id) and then not Has_Stable_Name (Id) then
         Failure := (Kind => Missing_Stable_Name, Command => Id);
         Found := True;
         return;
      end if;

      if D.Bindable and then not Is_Concrete_Command (Id) then
         Failure := (Kind => Invalid_Bindability, Command => Id);
         Found := True;
         return;
      end if;

      if not Has_Availability_Handler (Id) then
         Failure := (Kind => Missing_Availability, Command => Id);
         Found := True;
         return;
      end if;

      if not Descriptor_Is_Complete (Id) then
         Failure := (Kind => Missing_Classification, Command => Id);
         Found := True;
      end if;
   end Audit_Command;

   function Audit_Command_Registry
      return Command_Audit_Failure_Vectors.Vector
   is
      Result  : Command_Audit_Failure_Vectors.Vector;
      Failure : Command_Audit_Failure;
      Found   : Boolean;
   begin
      for Id in Command_Id loop
         if Is_Concrete_Command (Id) then
            Audit_Command (Id, Failure, Found);
            if Found then
               Result.Append (Failure);
            end if;
         end if;
      end loop;

      return Result;
   end Audit_Command_Registry;

   function Command_Audit_Summary
     (Failures : Command_Audit_Failure_Vectors.Vector) return String
   is
      Text : Unbounded_String := Null_Unbounded_String;

      function Failure_Text
        (Kind : Command_Audit_Failure_Kind) return String
      is
      begin
         case Kind is
            when Missing_Descriptor =>
               return "missing descriptor";
            when Missing_Label =>
               return "missing label";
            when Missing_Description =>
               return "missing description";
            when Missing_Category =>
               return "missing category";
            when Missing_Stable_Name =>
               return "missing stable command name";
            when Duplicate_Stable_Name =>
               return "duplicate stable command name";
            when Missing_Availability =>
               return "missing availability handler";
            when Missing_Executor_Handling =>
               return "missing Executor handling";
            when Invalid_Bindability =>
               return "invalid bindability";
            when Invalid_Default_Keybinding =>
               return "invalid default keybinding";
            when Missing_Classification =>
               return "missing classification";
            when Ambiguous_Save_Command =>
               return "ambiguous save command classification";
            when Route_Bypasses_Executor =>
               return "route bypasses Executor";
            when Unexpected_Domain_Mutation =>
               return "unexpected side-effect domain mutation";
         end case;
      end Failure_Text;
   begin
      if Failures.Is_Empty then
         return "Command audit passed";
      end if;

      Append (Text, "Command audit failed:");
      for Failure of Failures loop
         Append (Text, ASCII.LF);
         Append (Text, "  ");
         Append (Text, Command_Id'Image (Failure.Command));
         Append (Text, ": ");
         Append (Text, Failure_Text (Failure.Kind));
      end loop;

      return To_String (Text);
   end Command_Audit_Summary;

end Editor.Commands.Audits;
