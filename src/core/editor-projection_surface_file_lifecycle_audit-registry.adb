with Editor.Projection_Surface_File_Lifecycle_Audit.Adapters; use Editor.Projection_Surface_File_Lifecycle_Audit.Adapters;
with Editor.Projection_Surface_File_Lifecycle_Audit.Surface_Checks; use Editor.Projection_Surface_File_Lifecycle_Audit.Surface_Checks;

package body Editor.Projection_Surface_File_Lifecycle_Audit.Registry is

   function Classification_Name
     (Classification : Projection_Surface_Classification) return String
   is
   begin
      case Classification is
         when Projection_Surface_None           => return "none";
         when Projection_Surface_File_Like      => return "file-like";
         when Projection_Surface_Buffer_Like    => return "buffer-like";
         when Projection_Surface_Path_Like      => return "path-like";
         when Projection_Surface_Target_Like    => return "target-like";
         when Projection_Surface_Candidate_Like => return "candidate-like";
         when Projection_Surface_Result_Like    => return "result-like";
         when Projection_Surface_Bookmark_Like  => return "bookmark-like";
         when Projection_Surface_History_Like   => return "history-like";
         when Projection_Surface_Mixed          => return "mixed";
      end case;
   end Classification_Name;

   function Surface_Classification
     (Surface : Projection_Surface_Id) return Projection_Surface_Classification
   is
   begin
      case Surface is
         when Open_Buffer_Switcher_Surface =>
            return Projection_Surface_Buffer_Like;
         when Quick_Open_Surface =>
            return Projection_Surface_Candidate_Like;
         when Project_Search_Surface =>
            return Projection_Surface_Result_Like;
         when Bookmarks_Surface =>
            return Projection_Surface_Bookmark_Like;
         when Navigation_History_Surface =>
            return Projection_Surface_History_Like;
      end case;
   end Surface_Classification;

   function Registration_For_Surface
     (Surface : Projection_Surface_Id) return Projection_Surface_Registration
   is
      R : Projection_Surface_Registration :=
        (Surface                         => Surface,
         Classification                  => Surface_Classification (Surface),
         Is_Registered                   => True,
         Rows_May_Contain_Buffer_Identity => True,
         Rows_May_Contain_Retained_Target => True,
         Rows_May_Contain_Path_File_Labels => True,
         Rows_May_Contain_Dirty_Hints    => True,
         Rows_May_Contain_Current_Markers => True,
         Has_Query_Or_Filter_Text        => False,
         Has_Selected_Or_Current_Row     => True,
         Has_Activation_Behavior         => True,
         Has_Retained_Persistence        => False,
         Has_Surface_Adapter_Factory     => True,
         Has_Forbidden_Field_Metadata    => True,
         Has_Forbidden_Route_Metadata    => True,
         Has_Persistence_Inspection_Hook => True,
         Has_Render_Snapshot_Inspection_Hook => True,
         Runs_Shared_Invariant_Harness   => True);
   begin
      case Surface is
         when Open_Buffer_Switcher_Surface =>
            R.Rows_May_Contain_Retained_Target := False;
         when Quick_Open_Surface =>
            R.Has_Query_Or_Filter_Text := True;
         when Project_Search_Surface =>
            R.Has_Query_Or_Filter_Text := True;
            R.Has_Retained_Persistence := True;
         when Bookmarks_Surface =>
            R.Has_Retained_Persistence := True;
         when Navigation_History_Surface =>
            R.Has_Retained_Persistence := True;
      end case;
      return R;
   end Registration_For_Surface;

   function Surface_Is_Registered
     (Surface : Projection_Surface_Id) return Boolean
   is
   begin
      return Registration_For_Surface (Surface).Is_Registered;
   end Surface_Is_Registered;

   function Registration_Lifecycle_Sensitive
     (Registration : Projection_Surface_Registration) return Boolean
   is
   begin
      return Registration.Classification /= Projection_Surface_None
        or else Registration.Rows_May_Contain_Buffer_Identity
        or else Registration.Rows_May_Contain_Retained_Target
        or else Registration.Rows_May_Contain_Path_File_Labels
        or else Registration.Rows_May_Contain_Dirty_Hints
        or else Registration.Rows_May_Contain_Current_Markers;
   end Registration_Lifecycle_Sensitive;

   function Projection_Surface_Registration_Coherent
     (Registration : Projection_Surface_Registration) return Boolean
   is
   begin
      return (not Registration_Lifecycle_Sensitive (Registration)
              or else Registration.Is_Registered)
        and then (Registration.Classification = Projection_Surface_None
                  or else Registration.Runs_Shared_Invariant_Harness)
        and then (not Registration.Is_Registered
                  or else Registration.Has_Surface_Adapter_Factory)
        and then (not Registration.Is_Registered
                  or else Registration.Has_Forbidden_Field_Metadata)
        and then (not Registration.Is_Registered
                  or else Registration.Has_Forbidden_Route_Metadata)
        and then (not Registration.Has_Retained_Persistence
                  or else Registration.Has_Persistence_Inspection_Hook)
        and then (not Registration.Is_Registered
                  or else Registration.Has_Render_Snapshot_Inspection_Hook)
        and then Adapter_Supports_Shared_Harness
          (Adapter_For_Surface (Registration.Surface));
   end Projection_Surface_Registration_Coherent;

   function Projection_Surface_Inspection_Lifecycle_Sensitive
     (Inspection : Projection_Surface_Inspection) return Boolean
   is
   begin
      return Inspection.Classification /= Projection_Surface_None
        or else Inspection.Exposes_Buffer_Identity
        or else Inspection.Exposes_Retained_Target
        or else Inspection.Exposes_Path_File_Label
        or else Inspection.Exposes_Dirty_Hint
        or else Inspection.Exposes_Current_Or_Open_Marker
        or else Inspection.Exposes_Candidate_Result_Target
        or else Inspection.Exposes_Bookmark_Or_History_Target
        or else Inspection.Has_Local_Lifecycle_Route
        or else Inspection.Has_Target_Prompt_Ownership
        or else Inspection.Has_Source_Override_Or_Target_Inference
        or else Inspection.Has_Repair_Migration_Or_Probe
        or else Inspection.Has_Cross_Surface_Import
        or else Inspection.Has_Lifecycle_Persistence_Field;
   end Projection_Surface_Inspection_Lifecycle_Sensitive;

   function Projection_Surface_Inspection_Coherent
     (Inspection : Projection_Surface_Inspection) return Boolean
   is
      Sensitive : constant Boolean :=
        Projection_Surface_Inspection_Lifecycle_Sensitive (Inspection);
   begin
      if Inspection.Has_Explicit_Audit_Exemption then
         return not Inspection.Registered
           and then Inspection.Classification = Projection_Surface_None
           and then not Inspection.Has_Local_Lifecycle_Route
           and then not Inspection.Has_Lifecycle_Persistence_Field
           and then not Inspection.Has_Retained_Persistence;
      end if;

      return (not Sensitive or else Inspection.Registered)
        and then (Inspection.Registered or else not Inspection.Has_Retained_Persistence)
        and then (Inspection.Classification /= Projection_Surface_None
                  or else not Inspection.Exposes_Buffer_Identity)
        and then (Inspection.Classification /= Projection_Surface_None
                  or else not Inspection.Exposes_Retained_Target)
        and then (Inspection.Classification /= Projection_Surface_None
                  or else not Inspection.Exposes_Path_File_Label)
        and then (Inspection.Classification /= Projection_Surface_None
                  or else not Inspection.Exposes_Dirty_Hint)
        and then (Inspection.Classification /= Projection_Surface_None
                  or else not Inspection.Exposes_Current_Or_Open_Marker);
   end Projection_Surface_Inspection_Coherent;

   function Build_Future_Surface_Projection_Surface_Adapter
     (Surface        : Projection_Surface_Id;
      Classification : Projection_Surface_Classification)
      return Projection_Surface_Adapter
   is
      pragma Unreferenced (Classification);
   begin
      --  Template adapter for future surfaces: expose raw retained state and
      --  metadata to the shared harness.  It deliberately does not normalize,
      --  repair, infer, probe, execute commands, or mask persistence output.
      return Adapter_For_Surface (Surface);
   end Build_Future_Surface_Projection_Surface_Adapter;

   procedure Validate_Projection_Surface_Registration
     (Result       : in out Projection_Surface_Audit_Result;
      Registration : Projection_Surface_Registration)
   is
   begin
      if Registration_Lifecycle_Sensitive (Registration)
        and then not Registration.Is_Registered
      then
         Add_Failure
           (Result, Registration.Surface,
            "lifecycle-sensitive projection surface is not registered");
      end if;

      if Registration.Classification /= Projection_Surface_None
        and then not Registration.Runs_Shared_Invariant_Harness
      then
         Add_Failure
           (Result, Registration.Surface,
            "registered projection surface does not run shared invariant harness");
      end if;

      if Registration.Is_Registered and then not Registration.Has_Surface_Adapter_Factory then
         Add_Failure (Result, Registration.Surface, "registration does not expose adapter factory");
      end if;
      if Registration.Is_Registered and then not Registration.Has_Forbidden_Field_Metadata then
         Add_Failure (Result, Registration.Surface, "registration does not expose forbidden field metadata");
      end if;
      if Registration.Is_Registered and then not Registration.Has_Forbidden_Route_Metadata then
         Add_Failure (Result, Registration.Surface, "registration does not expose forbidden route metadata");
      end if;
      if Registration.Has_Retained_Persistence and then not Registration.Has_Persistence_Inspection_Hook then
         Add_Failure (Result, Registration.Surface, "retained surface persistence lacks inspection hook");
      end if;
      if Registration.Is_Registered and then not Registration.Has_Render_Snapshot_Inspection_Hook then
         Add_Failure (Result, Registration.Surface, "registration does not expose render snapshot inspection hook");
      end if;

      if Registration.Is_Registered then
         Validate_Adapter (Result, Adapter_For_Surface (Registration.Surface));
      end if;
   end Validate_Projection_Surface_Registration;

   procedure Validate_Projection_Surface_Inspection
     (Result     : in out Projection_Surface_Audit_Result;
      Inspection : Projection_Surface_Inspection)
   is
      Sensitive : constant Boolean :=
        Projection_Surface_Inspection_Lifecycle_Sensitive (Inspection);
   begin
      if Inspection.Has_Explicit_Audit_Exemption then
         if Inspection.Registered then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "audit exemption cannot replace an existing registration");
         end if;
         if Inspection.Classification /= Projection_Surface_None then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "audit exemption must remain non-lifecycle classified");
         end if;
         if Inspection.Has_Local_Lifecycle_Route then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "audit exemption cannot allow local lifecycle route");
         end if;
         if Inspection.Has_Lifecycle_Persistence_Field then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "audit exemption cannot allow lifecycle persistence field");
         end if;
         if Inspection.Has_Retained_Persistence then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "audit exemption cannot hide retained persistence");
         end if;
         return;
      end if;

      if Sensitive and then not Inspection.Registered then
         Add_Failure
           (Result, Open_Buffer_Switcher_Surface,
            "unregistered projection surface exposes lifecycle-sensitive row state");
      end if;

      if Inspection.Classification = Projection_Surface_None then
         if Inspection.Exposes_Buffer_Identity then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "none-classified surface exposes buffer identity");
         end if;
         if Inspection.Exposes_Retained_Target then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "none-classified surface exposes retained target");
         end if;
         if Inspection.Exposes_Path_File_Label then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "none-classified surface exposes path/file label");
         end if;
         if Inspection.Exposes_Dirty_Hint then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "none-classified surface exposes dirty hint");
         end if;
         if Inspection.Exposes_Current_Or_Open_Marker then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "none-classified surface exposes current/open marker");
         end if;
      end if;

      if not Inspection.Registered then
         if Inspection.Has_Local_Lifecycle_Route then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "unregistered surface owns local lifecycle route");
         end if;
         if Inspection.Has_Target_Prompt_Ownership then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "unregistered surface owns target prompt");
         end if;
         if Inspection.Has_Source_Override_Or_Target_Inference then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "unregistered surface owns source override or target inference");
         end if;
         if Inspection.Has_Repair_Migration_Or_Probe then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "unregistered surface owns repair, migration, or filesystem probe");
         end if;
         if Inspection.Has_Cross_Surface_Import then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "unregistered surface imports cross-surface projection truth");
         end if;
         if Inspection.Has_Retained_Persistence then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "unregistered surface has retained persistence without gate");
         end if;
         if Inspection.Has_Lifecycle_Persistence_Field then
            Add_Failure (Result, Open_Buffer_Switcher_Surface, "unregistered surface persists lifecycle observation field");
         end if;
      end if;
   end Validate_Projection_Surface_Inspection;


end Editor.Projection_Surface_File_Lifecycle_Audit.Registry;
