with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality is

   use type Scope_Consumer.Accessibility_Consumer_Row_Id;
   use type Object_Flow.Object_Flow_Row_Id;
   use type Disc_Consumer.Discriminant_Consumer_Row_Id;
   use type Backmap.Generic_Backmap_Row_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Disc_Consumer.Discriminant_Consumer_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 17) mod 2_147_483_647;
   end Mix;

   function Has (S, Pattern : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (S, Pattern) /= 0;
   end Has;

   function Is_Enum_Legal (Image : String) return Boolean is
   begin
      return Has (Image, "LEGAL") or else Has (Image, "ACCEPTED");
   end Is_Enum_Legal;

   function Is_Enum_Indeterminate (Image : String) return Boolean is
   begin
      return Has (Image, "INDETERMINATE") or else Has (Image, "NOT_CHECKED");
   end Is_Enum_Indeterminate;

   function Scope_Image
     (Status : Scope_Consumer.Accessibility_Consumer_Status) return String is
   begin
      return Scope_Consumer.Accessibility_Consumer_Status'Image (Status);
   end Scope_Image;

   function Object_Flow_Image
     (Status : Object_Flow.Object_Flow_Status) return String is
   begin
      return Object_Flow.Object_Flow_Status'Image (Status);
   end Object_Flow_Image;

   function Backmap_Image
     (Status : Backmap.Generic_Backmap_Status) return String is
   begin
      return Backmap.Generic_Backmap_Status'Image (Status);
   end Backmap_Image;

   function Legal_Status_For_Kind
     (Kind : Master_Scope_Final_Context_Kind) return Master_Scope_Final_Status is
   begin
      case Kind is
         when Master_Scope_Final_Anonymous_Access_Result =>
            return Master_Scope_Final_Legal_Anonymous_Access_Result_Accepted;
         when Master_Scope_Final_Anonymous_Access_Parameter =>
            return Master_Scope_Final_Legal_Anonymous_Access_Parameter_Accepted;
         when Master_Scope_Final_Access_Discriminant =>
            return Master_Scope_Final_Legal_Access_Discriminant_Accepted;
         when Master_Scope_Final_Allocator_Master =>
            return Master_Scope_Final_Legal_Allocator_Master_Accepted;
         when Master_Scope_Final_Aggregate_Access_Component =>
            return Master_Scope_Final_Legal_Aggregate_Access_Component_Accepted;
         when Master_Scope_Final_Access_Conversion =>
            return Master_Scope_Final_Legal_Access_Conversion_Accepted;
         when Master_Scope_Final_Return_Object =>
            return Master_Scope_Final_Legal_Return_Object_Accepted;
         when Master_Scope_Final_Return_Access =>
            return Master_Scope_Final_Legal_Return_Access_Accepted;
         when Master_Scope_Final_Generic_Access_Actual =>
            return Master_Scope_Final_Legal_Generic_Access_Actual_Accepted;
         when Master_Scope_Final_Generic_Replay_Escape =>
            return Master_Scope_Final_Legal_Generic_Replay_Escape_Accepted;
         when Master_Scope_Final_Renaming =>
            return Master_Scope_Final_Legal_Renaming_Accepted;
         when Master_Scope_Final_Controlled_Finalization =>
            return Master_Scope_Final_Legal_Controlled_Finalization_Accepted;
         when Master_Scope_Final_Private_Full_View =>
            return Master_Scope_Final_Legal_Private_Full_View_Accepted;
         when Master_Scope_Final_Cross_Unit_Lifetime =>
            return Master_Scope_Final_Legal_Cross_Unit_Lifetime_Accepted;
         when Master_Scope_Final_Unknown =>
            return Master_Scope_Final_Indeterminate;
      end case;
   end Legal_Status_For_Kind;

   function Status_From_Scope
     (Status : Scope_Consumer.Accessibility_Consumer_Status;
      Kind   : Master_Scope_Final_Context_Kind) return Master_Scope_Final_Status is
      Img : constant String := Scope_Image (Status);
   begin
      if Is_Enum_Legal (Img) then
         return Master_Scope_Final_Not_Checked;
      elsif Is_Enum_Indeterminate (Img) then
         return Master_Scope_Final_Scope_Consumer_Indeterminate;
      elsif Has (Img, "ANONYMOUS") and then Has (Img, "ESCAPE") then
         return Master_Scope_Final_Anonymous_Access_Result_Escapes;
      elsif Has (Img, "ACCESS_PARAMETER_ESCAPES") then
         return Master_Scope_Final_Access_Parameter_Escapes;
      elsif Has (Img, "ACCESS_DISCRIMINANT") then
         return Master_Scope_Final_Access_Discriminant_Master_Blocker;
      elsif Has (Img, "ALLOCATOR") then
         return Master_Scope_Final_Allocator_Master_Blocker;
      elsif Has (Img, "RETURN_OBJECT") then
         return Master_Scope_Final_Return_Object_Master_Blocker;
      elsif Has (Img, "RETURN_ACCESS") then
         return Master_Scope_Final_Return_Access_Master_Blocker;
      elsif Has (Img, "ACCESS_CONVERSION") or else Has (Img, "STATIC_LEVEL") or else Has (Img, "DYNAMIC_LEVEL") then
         return Master_Scope_Final_Access_Conversion_Level_Blocker;
      elsif Has (Img, "GENERIC") then
         return Master_Scope_Final_Generic_Access_Escape_Blocker;
      elsif Has (Img, "RENAMING") or else Has (Img, "DANGLING") then
         return Master_Scope_Final_Renaming_Dangling_Blocker;
      elsif Has (Img, "FINALIZATION") then
         return Master_Scope_Final_Finalization_Master_Blocker;
      elsif Has (Img, "DISCRIMINANT") then
         return Master_Scope_Final_Discriminant_Variant_Blocker;
      elsif Has (Img, "REPRESENTATION") then
         return Master_Scope_Final_Representation_Freezing_Blocker;
      elsif Has (Img, "COVERAGE") then
         return Master_Scope_Final_Coverage_Blocker;
      else
         case Kind is
            when Master_Scope_Final_Aggregate_Access_Component =>
               return Master_Scope_Final_Aggregate_Access_Master_Blocker;
            when Master_Scope_Final_Private_Full_View =>
               return Master_Scope_Final_Private_Full_View_Lifetime_Blocker;
            when Master_Scope_Final_Cross_Unit_Lifetime =>
               return Master_Scope_Final_Cross_Unit_Lifetime_Blocker;
            when others =>
               return Master_Scope_Final_Scope_Consumer_Blocker;
         end case;
      end if;
   end Status_From_Scope;

   function Status_From_Object_Flow
     (Status : Object_Flow.Object_Flow_Status;
      Kind   : Master_Scope_Final_Context_Kind) return Master_Scope_Final_Status is
      Img : constant String := Object_Flow_Image (Status);
   begin
      if Is_Enum_Legal (Img) then
         return Master_Scope_Final_Not_Checked;
      elsif Is_Enum_Indeterminate (Img) then
         return Master_Scope_Final_Object_Flow_Indeterminate;
      elsif Has (Img, "RETURN_OBJECT") then
         return Master_Scope_Final_Return_Object_Master_Blocker;
      elsif Has (Img, "RETURN_ACCESS") then
         return Master_Scope_Final_Return_Access_Master_Blocker;
      elsif Has (Img, "ALLOCATOR") then
         return Master_Scope_Final_Allocator_Master_Blocker;
      elsif Has (Img, "ACCESS_DISCRIMINANT") then
         return Master_Scope_Final_Access_Discriminant_Master_Blocker;
      elsif Has (Img, "ACCESS_PARAMETER_ESCAPES") or else Has (Img, "ANONYMOUS") then
         return Master_Scope_Final_Access_Parameter_Escapes;
      elsif Has (Img, "ACCESS_CONVERSION") or else Has (Img, "LEVEL") then
         return Master_Scope_Final_Access_Conversion_Level_Blocker;
      elsif Has (Img, "GENERIC") then
         return Master_Scope_Final_Generic_Access_Escape_Blocker;
      elsif Has (Img, "RENAMING") or else Has (Img, "DANGLING") then
         return Master_Scope_Final_Renaming_Dangling_Blocker;
      elsif Has (Img, "FINALIZATION") then
         return Master_Scope_Final_Finalization_Master_Blocker;
      elsif Has (Img, "DISCRIMINANT") then
         return Master_Scope_Final_Discriminant_Variant_Blocker;
      elsif Has (Img, "REPRESENTATION") then
         return Master_Scope_Final_Representation_Freezing_Blocker;
      elsif Has (Img, "COVERAGE") then
         return Master_Scope_Final_Coverage_Blocker;
      else
         case Kind is
            when Master_Scope_Final_Aggregate_Access_Component =>
               return Master_Scope_Final_Aggregate_Access_Master_Blocker;
            when Master_Scope_Final_Anonymous_Access_Result =>
               return Master_Scope_Final_Anonymous_Access_Result_Escapes;
            when others =>
               return Master_Scope_Final_Object_Flow_Blocker;
         end case;
      end if;
   end Status_From_Object_Flow;

   function Status_From_Discriminant
     (Status : Disc_Consumer.Discriminant_Consumer_Status) return Master_Scope_Final_Status is
   begin
      if Disc_Consumer.Is_Legal (Status) then
         return Master_Scope_Final_Not_Checked;
      elsif Status = Disc_Consumer.Discriminant_Consumer_Indeterminate then
         return Master_Scope_Final_Discriminant_Consumer_Indeterminate;
      elsif Disc_Consumer.Is_Representation_Error (Status) then
         return Master_Scope_Final_Representation_Freezing_Blocker;
      else
         return Master_Scope_Final_Discriminant_Consumer_Blocker;
      end if;
   end Status_From_Discriminant;

   function Status_From_Backmap
     (Status : Backmap.Generic_Backmap_Status) return Master_Scope_Final_Status is
      Img : constant String := Backmap_Image (Status);
   begin
      if Backmap.Is_Legal (Status) then
         return Master_Scope_Final_Not_Checked;
      elsif Is_Enum_Indeterminate (Img) then
         return Master_Scope_Final_Generic_Backmap_Indeterminate;
      else
         return Master_Scope_Final_Generic_Backmap_Blocker;
      end if;
   end Status_From_Backmap;

   function Status_For (Info : Master_Scope_Final_Context_Info) return Master_Scope_Final_Status is
      Candidate : Master_Scope_Final_Status;
   begin
      if Info.Scope_Consumer_Matches > 1 then
         return Master_Scope_Final_Multiple_Scope_Consumer_Blockers;
      elsif Info.Scope_Consumer_Row = Scope_Consumer.No_Accessibility_Consumer_Row then
         return Master_Scope_Final_Missing_Scope_Consumer_Row;
      end if;

      Candidate := Status_From_Scope (Info.Scope_Consumer_Status, Info.Kind);
      if Candidate /= Master_Scope_Final_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_Object_Flow then
         if Info.Object_Flow_Matches > 1 then
            return Master_Scope_Final_Multiple_Object_Flow_Blockers;
         elsif Info.Object_Flow_Row = Object_Flow.No_Object_Flow_Row then
            return Master_Scope_Final_Missing_Object_Flow_Row;
         end if;

         Candidate := Status_From_Object_Flow (Info.Object_Flow_Status, Info.Kind);
         if Candidate /= Master_Scope_Final_Not_Checked then
            return Candidate;
         end if;
      end if;

      if Info.Requires_Discriminant then
         if Info.Discriminant_Matches > 1 then
            return Master_Scope_Final_Multiple_Discriminant_Consumer_Blockers;
         elsif Info.Discriminant_Row = Disc_Consumer.No_Discriminant_Consumer_Row then
            return Master_Scope_Final_Missing_Discriminant_Consumer_Row;
         end if;

         Candidate := Status_From_Discriminant (Info.Discriminant_Status);
         if Candidate /= Master_Scope_Final_Not_Checked then
            return Candidate;
         end if;
      end if;

      if Info.Requires_Generic_Backmap then
         if Info.Generic_Backmap_Matches > 1 then
            return Master_Scope_Final_Multiple_Generic_Backmap_Blockers;
         elsif Info.Generic_Backmap_Row = Backmap.No_Generic_Backmap_Row then
            return Master_Scope_Final_Missing_Generic_Backmap_Row;
         end if;

         Candidate := Status_From_Backmap (Info.Generic_Backmap_Status);
         if Candidate /= Master_Scope_Final_Not_Checked then
            return Candidate;
         end if;
      end if;

      return Legal_Status_For_Kind (Info.Kind);
   end Status_For;

   function Message_For (Status : Master_Scope_Final_Status) return Unbounded_String is
   begin
      if Is_Legal (Status) then
         return To_Unbounded_String ("accessibility master/scope evidence accepted");
      elsif Is_Indeterminate (Status) then
         return To_Unbounded_String ("accessibility master/scope evidence is indeterminate");
      else
         return To_Unbounded_String ("accessibility master/scope evidence blocks confident legality");
      end if;
   end Message_For;

   function Fingerprint_For (Info : Master_Scope_Final_Info) return Natural is
      Result : Natural := Natural (Info.Id);
   begin
      Result := Mix (Result, Master_Scope_Final_Status'Pos (Info.Status));
      Result := Mix (Result, Master_Scope_Final_Context_Kind'Pos (Info.Kind));
      Result := Mix (Result, Natural (Info.Node));
      Result := Mix (Result, Info.Source_Fingerprint);
      Result := Mix (Result, Info.Scope_Fingerprint);
      Result := Mix (Result, Info.Object_Flow_Fingerprint);
      Result := Mix (Result, Info.Consumer_Fingerprint);
      return Result;
   end Fingerprint_For;

   procedure Clear (Model : in out Master_Scope_Final_Context_Model) is
   begin
      Model.Contexts.Clear;
   end Clear;

   procedure Add_Context
     (Model : in out Master_Scope_Final_Context_Model;
      Info  : Master_Scope_Final_Context_Info) is
   begin
      Model.Contexts.Append (Info);
   end Add_Context;

   function Context_Count (Model : Master_Scope_Final_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Master_Scope_Final_Context_Model;
      Index : Positive) return Master_Scope_Final_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Master_Scope_Final_Context_Model) return Natural is
      Result : Natural := 0;
   begin
      for C of Model.Contexts loop
         Result := Mix (Result, Natural (C.Id));
         Result := Mix (Result, Master_Scope_Final_Context_Kind'Pos (C.Kind));
         Result := Mix (Result, Natural (C.Node));
         Result := Mix (Result, C.Source_Fingerprint);
         Result := Mix (Result, C.Scope_Fingerprint);
         Result := Mix (Result, C.Object_Flow_Fingerprint);
         Result := Mix (Result, C.Consumer_Fingerprint);
      end loop;
      return Result;
   end Fingerprint;

   function Build
     (Contexts : Master_Scope_Final_Context_Model) return Master_Scope_Final_Model is
      Model : Master_Scope_Final_Model;
      Row   : Master_Scope_Final_Info;
      Status : Master_Scope_Final_Status;
   begin
      for C of Contexts.Contexts loop
         Status := Status_For (C);
         Row :=
           (Id                      => C.Id,
            Context                 => C.Id,
            Kind                    => C.Kind,
            Status                  => Status,
            Node                    => C.Node,
            Object_Name             => C.Object_Name,
            Type_Name               => C.Type_Name,
            Generic_Unit_Name       => C.Generic_Unit_Name,
            Instance_Name           => C.Instance_Name,
            Message                 => Message_For (Status),
            Detail                  => To_Unbounded_String (Master_Scope_Final_Status'Image (Status)),
            Scope_Consumer_Row      => C.Scope_Consumer_Row,
            Scope_Consumer_Status   => C.Scope_Consumer_Status,
            Object_Flow_Row         => C.Object_Flow_Row,
            Object_Flow_Status      => C.Object_Flow_Status,
            Discriminant_Row        => C.Discriminant_Row,
            Discriminant_Status     => C.Discriminant_Status,
            Generic_Backmap_Row     => C.Generic_Backmap_Row,
            Generic_Backmap_Status  => C.Generic_Backmap_Status,
            Source_Fingerprint      => C.Source_Fingerprint,
            Scope_Fingerprint       => C.Scope_Fingerprint,
            Object_Flow_Fingerprint => C.Object_Flow_Fingerprint,
            Consumer_Fingerprint    => C.Consumer_Fingerprint,
            Fingerprint             => 0);
         Row.Fingerprint := Fingerprint_For (Row);
         Model.Rows.Append (Row);
         Model.Model_Fingerprint := Mix (Model.Model_Fingerprint, Row.Fingerprint);
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Master_Scope_Final_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Master_Scope_Final_Model;
      Index : Positive) return Master_Scope_Final_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Master_Scope_Final_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Master_Scope_Final_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Master_Scope_Final_Model;
      Status : Master_Scope_Final_Status) return Master_Scope_Final_Set is
      Result : Master_Scope_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Master_Scope_Final_Model;
      Kind  : Master_Scope_Final_Context_Kind) return Master_Scope_Final_Set is
      Result : Master_Scope_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Rows_For_Object
     (Model       : Master_Scope_Final_Model;
      Object_Name : String) return Master_Scope_Final_Set is
      Result : Master_Scope_Final_Set;
   begin
      for Row of Model.Rows loop
         if To_String (Row.Object_Name) = Object_Name then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Object;

   function Set_Count (Set : Master_Scope_Final_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Set_Count;

   function Set_At
     (Set   : Master_Scope_Final_Set;
      Index : Positive) return Master_Scope_Final_Info is
   begin
      return Set.Rows.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Master_Scope_Final_Model;
      Status : Master_Scope_Final_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Master_Scope_Final_Model;
      Kind  : Master_Scope_Final_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Master_Scope_Final_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Master_Scope_Final_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if not Is_Legal (Row.Status) and then not Is_Indeterminate (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Scope_Error_Count (Model : Master_Scope_Final_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Scope_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Scope_Error_Count;

   function Object_Flow_Error_Count (Model : Master_Scope_Final_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Object_Flow_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Object_Flow_Error_Count;

   function Discriminant_Error_Count (Model : Master_Scope_Final_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Discriminant_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Discriminant_Error_Count;

   function Generic_Backmap_Error_Count (Model : Master_Scope_Final_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Generic_Backmap_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Generic_Backmap_Error_Count;

   function Lifetime_Error_Count (Model : Master_Scope_Final_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Lifetime_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Lifetime_Error_Count;

   function Indeterminate_Count (Model : Master_Scope_Final_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Indeterminate_Count;

   function Fingerprint (Model : Master_Scope_Final_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

   function Is_Legal (Status : Master_Scope_Final_Status) return Boolean is
   begin
      return Status in Master_Scope_Final_Legal_Anonymous_Access_Result_Accepted ..
                       Master_Scope_Final_Legal_Cross_Unit_Lifetime_Accepted;
   end Is_Legal;

   function Is_Scope_Error (Status : Master_Scope_Final_Status) return Boolean is
   begin
      return Status in Master_Scope_Final_Missing_Scope_Consumer_Row |
                       Master_Scope_Final_Scope_Consumer_Blocker |
                       Master_Scope_Final_Multiple_Scope_Consumer_Blockers;
   end Is_Scope_Error;

   function Is_Object_Flow_Error (Status : Master_Scope_Final_Status) return Boolean is
   begin
      return Status in Master_Scope_Final_Missing_Object_Flow_Row |
                       Master_Scope_Final_Object_Flow_Blocker |
                       Master_Scope_Final_Multiple_Object_Flow_Blockers;
   end Is_Object_Flow_Error;

   function Is_Discriminant_Error (Status : Master_Scope_Final_Status) return Boolean is
   begin
      return Status in Master_Scope_Final_Missing_Discriminant_Consumer_Row |
                       Master_Scope_Final_Discriminant_Consumer_Blocker |
                       Master_Scope_Final_Discriminant_Variant_Blocker |
                       Master_Scope_Final_Multiple_Discriminant_Consumer_Blockers;
   end Is_Discriminant_Error;

   function Is_Generic_Backmap_Error (Status : Master_Scope_Final_Status) return Boolean is
   begin
      return Status in Master_Scope_Final_Missing_Generic_Backmap_Row |
                       Master_Scope_Final_Generic_Backmap_Blocker |
                       Master_Scope_Final_Multiple_Generic_Backmap_Blockers;
   end Is_Generic_Backmap_Error;

   function Is_Lifetime_Error (Status : Master_Scope_Final_Status) return Boolean is
   begin
      return Status in Master_Scope_Final_Anonymous_Access_Result_Escapes |
                       Master_Scope_Final_Access_Parameter_Escapes |
                       Master_Scope_Final_Access_Discriminant_Master_Blocker |
                       Master_Scope_Final_Allocator_Master_Blocker |
                       Master_Scope_Final_Aggregate_Access_Master_Blocker |
                       Master_Scope_Final_Access_Conversion_Level_Blocker |
                       Master_Scope_Final_Return_Object_Master_Blocker |
                       Master_Scope_Final_Return_Access_Master_Blocker |
                       Master_Scope_Final_Generic_Access_Escape_Blocker |
                       Master_Scope_Final_Renaming_Dangling_Blocker |
                       Master_Scope_Final_Finalization_Master_Blocker |
                       Master_Scope_Final_Private_Full_View_Lifetime_Blocker |
                       Master_Scope_Final_Cross_Unit_Lifetime_Blocker;
   end Is_Lifetime_Error;

   function Is_Indeterminate (Status : Master_Scope_Final_Status) return Boolean is
   begin
      return Status in Master_Scope_Final_Scope_Consumer_Indeterminate |
                       Master_Scope_Final_Object_Flow_Indeterminate |
                       Master_Scope_Final_Discriminant_Consumer_Indeterminate |
                       Master_Scope_Final_Generic_Backmap_Indeterminate |
                       Master_Scope_Final_Indeterminate;
   end Is_Indeterminate;

end Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
