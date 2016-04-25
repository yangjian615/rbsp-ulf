;+
;Procedure: tvector_rotate
;
;Purpose:  rotates array data by a set of coordinate
;          transformation matrices inputs and outputs are tplot
;          variables.  This is designed mainly for use with
;          fac_matrix_make.pro and minvar_matrix_make, but can be used
;          for more general purposes
;;          
;          Assuming that the data array and matrix time-grids match,
;          this code is the vectorized equivalent to:
;          for i=0,n_ele-1 do out[i,*]=reform(reform(m[i,*,*])#reform(v[i,*]))
;        
;          Setting the "invert" keyword will produce results that are equivalent to using the '##' 
;          operation in the loop above.
;          
;Warning:
; The transformation matrices generated by
;fac_matrix_make,thm_fac_matrix_make, and minvar_matrix_make are
;defined relative to a specific coordinate system.  This means that if
;you use vectors in one coordinate system to generate the rotation
;matrices they will only correctly transform data from that coordinate
;system into the functional coordinate system.
;
;  For example if you use
;magnetic field data in gsm to generate Rgeo transformation matrices
;using fac_matrix_make then the array being provided to tvector
;rotate to be transformed by those matrices should only be in gsm coordinates.

;
;Arguments:
;
; mat_var_in: the name of the tplot variable storing input matrices
; The y component of the tplot variable's data struct should be
; an Mx3x3 array, storing a list of transformation matrices. 
; Array data can be input as well and should be an Mx3x3 array
; 
;
; vec_var_in: The name of a tplot variable storing an array of input vectors.
; You can use globbing to rotate several tplot variables
; storing vectors with a single matrix. The y component of the tplot variable's
; data struct should be an Nx3 array. Array data can also be input and should be
; an Nx3 array. 
;
;
; newname(optional): the name of the output variable, defaults to 
;                    vec_var_in + '_rot'
;                    If you use type globbing in the vector variable
;                    If array data is used this variable should be 
;                    declared.
;
; suffix: The suffix to be appended to the tplot variables that the output matrices will be stored in.
;         (Default: '_rot')
;
; error(optional): named variable in which to return the error state
; of the computation.  1 = success 0 = failure
; 
; 
; invert(optional):  If matrix_var naturally transforms vector_var from Coord A to B,
;                    (ie Vb = M#Va where # denotes matrix multiplication) then setting
;                    this keyword will transform vector_var from Coord B to A( ie Va = M^T#Vb 
;                    This is done by transposing the input matrices, as it is a property of 
;                    rotation matrices that M#M^T = I and M^T#M = I(ie M^T = M^-1) 
;                    
; vector_skip_nonmonotonic(optional): Removes any vector data with non-ascending or repeated
;                            timestamps before SLERPing matrices rather than throwing an error.
;                            
; matrix_skip_nonmonotonic(optional): Removes any vector data with non-ascending 
;                            timestamps before SLERPing matrices rather than throwing an error.
;
;CALLING SEQUENCE:
;
; tvector_rotate,'matrix_var','vector_var',newname = 'out_var',error=error
;
; tvector_rotate,'matrix_var','vector_var'
;
;Notes: 
; 1.  mat_var_in should store rotation or permutation matrices. 
;     (ie the columns of any matrix in mat_var_in should form an orthonormal basis) 
;     tvector_rotate will test and warn if input matrices are inalid.
;     Permutation matrices are allowed so that coordinates can be transformed
;     from right to left handed systems and vice-versa.  This is verified via the following 
;     contraints.  
;     M#M^-1 = I and abs(determ(m)) = 1
;   
; 2.  transformation matrices generally only transform from one particular basis
;     to another particular basis.  Since tvector_rotate as no way to test that
;     vector_var is in the correct basis, you need to be very careful that
;     vector_var has the correct coordinate system and representation
;     so that it can correctly transform the data.
;     
;
;3.   If M!=N, then M must be >= 2 (where M,N refer to the dimensions of the
;     input variables.)
;
;4.  Also If the x components of mat_var_in and vec_var_in data structs
;    do not match then, the matrices will be interpolated to match the
;    cadence of the data.  Interpolation is done by turning the
;    matrices into quaternions and performing spherical linear
;    interpolation.  As noted above this interpolation behavior will
;    not be predictable if the matrices do anything other than rotate.
;
;5.  If the timestamps of mat_var_in are not monotonic(ascending or identical) or 
;    if the timestamps vec_var_in are not strictly monotonic(always ascending) the
;    program will not work correctly in the event that matrix SLERPing is required. 
;    Set the keywords vector_skip_nonmonotonic or matrix_skip_nonmonotonic to have
;    the routine remove the non-monotonic data when generating the output. Alternatively,
;    if matrix and vector timestamps match no SLERPing will be required, also fixing
;    nonmonotonicities manually will fix the problem.
;
; SEE ALSO:  mva_matrix_make.pro, fac_matrix_make.pro,rxy_matrix_make
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2015-12-09 11:12:24 -0800 (Wed, 09 Dec 2015) $
; $LastChangedRevision: 19554 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/special/tvector_rotate.pro $
;-

;helper function, reduces the time dimension of
;the input tplot struct to the specified indexes
function ctv_reduce_time_dimen,dat,idx

  compile_opt idl2, hidden

  if idx[0] eq -1 then return,dat

  str_element,dat,'x',dat.x[idx],/add_replace

  y_ndim = ndimen(dat.y)
  y_dim = dimen(dat.y)

  if y_ndim eq 1 then begin
    str_element,dat,'y',dat.y[idx],/add_replace
  endif else if y_ndim eq 2 then begin
    str_element,dat,'y',dat.y[idx,*],/add_replace
  endif else if y_ndim eq 3 then begin
    str_element,dat,'y',dat.y[idx,*,*],/add_replace
  endif else begin
    message,'Unexpected dimension error'
  endelse

  str_element,dat,'v',success=s

  if s then begin

    v_ndim = ndimen(dat.v)
    v_dim = dimen(dat.v)

    if y_dim[0] eq v_dim[0] && y_ndim eq v_ndim then begin
      if v_ndim eq 1 then begin
        str_element,dat,'v',dat.v[idx],/add_replace
      endif else if v_ndim eq 2 then begin
        str_element,dat,'v',dat.v[idx,*],/add_replace
      endif else if v_ndim eq 3 then begin
        str_element,dat,'v',dat.v[idx,*],/add_replace
      endif else begin
        message,'Unexpected dimension error'
      endelse
    endif
  endif

  return,dat

end

pro tvector_rotate,mat_var_in,vec_var_in,newname = newname,suffix=suffix,error=error,invert=invert,$
                   vector_skip_nonmonotonic=vector_skip_nonmonotonic,$
                   matrix_skip_nonmonotonic=matrix_skip_nonmonotonic

compile_opt idl2, hidden
;puts helper functions in scope
matrix_array_lib

error = 0

if not keyword_set(mat_var_in) then begin
    dprint,'FX requires the matrix variable to be set'
    return
endif

if size(mat_var_in, /type) eq 7 then tplotvar=1 else tplotvar=0

if tplotvar then begin

    if tnames(mat_var_in) eq '' then begin
        dprint,'FX requires the matrix variable to be set'
        return
    endif
    
    if not keyword_set(vec_var_in) then begin
        dprint,'FX requires vector variable to be set'
        return
    endif
    
    tn = tnames(vec_var_in)
    
    if size(tn,/n_dim) eq 0 && tn eq '' then begin
        dprint,'FX requires vector variable to be set'
        return
    endif
    
    if ~keyword_set(suffix) then begin
      suffix = '_rot'
    endif
    
    if ~keyword_set(newname) then begin
      newname = tn + suffix
    endif
    
    
    ;loop over possibly many vectors
    for i = 0,n_elements(tn) -1L do begin
    
        ;tinterpol_mxn,mat_var_in,tn[i],newname = mat_var_in+'_interp_temp',error=error_state
    
       ;load the matrices and validate dimensions
       get_data,mat_var_in,data=m_d,dlimits=m_dl ;rotation matrices and input abcissa values
       
       m_d_s = size(m_d.y,/dimensions)
    
       if(n_elements(m_d_s) ne 3 || m_d_s[1] ne 3 || m_d_s[2] ne 3) then begin
    
          dprint,'FX requires matrix data to contain an Nx3x3 array'
          return
       endif
    
       ;load the vectors and validate dimensions
       get_data,tn[i],data=v_d,dlimits=v_dl ;output abcissa values
       
       v_d_s = size(v_d.y,/dimensions)
    
       if(n_elements(v_d_s) ne 2 || v_d_s[1] ne 3) then begin
          dprint,'FX requires vector data to contain an Nx3 Array'
          return
       endif
    
       if array_equal(m_d.x,v_d.x) then begin
    
          m_d_y = m_d.y
          
          verify_check = ctv_verify_mats(m_d_y)
  
       endif else begin
          
           if min(v_d.x,/nan) gt max(m_d.x,/nan) || max(v_d.x) lt min(m_d.x) then begin
            dprint,'WARNING: time arrays for matrices and vectors do not overlap.'
            dprint,'Data is probably from different days.  Result will probably be incorrect.
          endif else begin
            dprint,'WARNING: time arrays do not match.  Matrices will be interpolated to match the times of input vector array'
          endelse
          
          if n_elements(m_d.x) gt 1 then begin
          
            idx = where((m_d.x[1:n_elements(m_d.x)-1]-m_d.x[0:n_elements(m_d.x)-2]) lt 0,complement=cidx)
    
            if(idx[0] ne -1) then begin
               
              ;modify the complement(monotonic entries) index, so it corresponds to regular entries, not discrete derivative entries.
              if cidx[0] eq -1 then begin
                cidx = [0]
              endif else begin
                cidx = [0,cidx+1]
              endelse
               
              ;if requested, repair by removing nonmonotonic entries.
              if keyword_set(matrix_skip_nonmonotonic) then begin
                dprint,'WARNING: ' + mat_var_in + ' timestamps are not monotonic. Removing ' + strtrim(n_elements(idx),2) + ' nonmonotonic matrix entries.'
                m_d = ctv_reduce_time_dimen(m_d,cidx)
              endif else begin
                dprint,'ERROR: Matrix timestamps not monotonic please remove any non-ascending timestamps from your data or set keyword: matrix_skip_nonmonotonic'
                return
              endelse
    
            endif
          endif
          
          ;check for nonmonotonic entries
          if n_elements(v_d.x) gt 1 then begin
        
            idx = where((v_d.x[1:n_elements(v_d.x)-1]-v_d.x[0:n_elements(v_d.x)-2]) le 0,complement=cidx)
    
            if(idx[0] ne -1) then begin
     
              ;modify the complement(monotonic entries) index, so it corresponds to regular entries, not discrete derivative entries.
              if cidx[0] eq -1 then begin
                cidx = [0]
              endif else begin
                cidx = [0,cidx+1]
              endelse
    
              ;if requested, repair by removing nonmonotonic entries.
              if keyword_set(vector_skip_nonmonotonic) then begin
                dprint,'WARNING: ' + tn[i] + ' timestamps not strictly monotonic. Removing ' + strtrim(n_elements(idx),2) + ' nonmonotonic vector entries.'
                v_d = ctv_reduce_time_dimen(v_d,cidx)
              endif else begin
                dprint, 'ERROR: Vector timestamps not monotonic please remove any non-ascending or repeated timestamps from your data or set keyword: vector_skip_nonmonotonic'
                return
              endelse
    
            endif
            
          endif
       
          verify_check = ctv_verify_mats(m_d.y)
          
          is_left_mat = ctv_left_mats(m_d.y)
          
          ;left-handed matrices can mess up qslerping
          if is_left_mat then begin
            q_in = mtoq(ctv_swap_hands(m_d.y)) ;this makes them right handed before quaternion conversion
          endif else begin
            ;using quaternion library transform into quanternions
            q_in = mtoq(m_d.y)
          endelse
    
          ;interpolate quaternions
          q_out = qslerp(q_in,m_d.x,v_d.x)
    
          ;turn quaternions back into matrices
          m_d_y = qtom(q_out)
    
          ;if we swapped before interpol, swap back
          if is_left_mat then begin
            m_d_y = ctv_swap_hands(m_d_y)
          endif
          
          ;if a dimension gets lost, add it back
          m_dim_tmp = dimen(m_d_y)
          if n_elements(m_dim_tmp) eq 2 && m_dim_tmp[0] eq 3 && m_dim_tmp[1] eq 3 then begin
            m_d_y = reform(m_d_y,1,3,3)
          endif
    
       endelse
       
       ;returns 0 if the matrices use a mixed system
       ;returns 1 if there are no valid mats
       ;returns 2 if the data are all nans
       ;returns 3 if there are some invalid mats
       ;returns 4 if there are some nans
       ;returns 5 win!
       if verify_check eq 0 then begin
         dprint,'ERROR: Input matrices contain rotations with determinants of both -1 and 1.  This may indicate an incorrectly formed rotation, or an high level of error in the rotation.',dlevel=1
       endif else if verify_check eq 1 then begin
         dprint,'ERROR: Input matrices are not valid rotation matries. This may indicate an incorrectly formed rotation, or an high level of error in the rotation.',dlevel=1
         ;decided against forced failure, as extreme numerical instability can create false positives for invalid tests
         ;return
       endif else if verify_check eq 2 then begin
         dprint,'ERROR: All input matrices contain non-finite values.(Infinity or NaN)   Results will be non-finite.',dlevel=1
       endif else if verify_check eq 3 then begin
         dprint,'WARNING: Some input matrices are not valid rotation matrices. You may want to verify the result',dlevel=2
       endif else if verify_check eq 4 then begin
         dprint,'WARNING: Some input matrices contain non-finite values.(Infinity or NaN)  Some results will be non-finite.' ,dlevel=2
       endif
       
       if(size(m_d_y,/n_dim) eq 0 && m_d_y[0] eq -1L) then begin
    
          dprint,'failed to interpolate rotation matrix array'
    
          return
    
       endif
       
       ;rotate vectors using matrix right multiplication
       
       ;if invert is set, then we transpose rotation matrices to construct inverse rotation matrix
       if keyword_set(invert) then begin
         v_t = ctv_mx_vec_rot(transpose(m_d_y,[0,2,1]),v_d.y)
       endif else begin
         v_t = ctv_mx_vec_rot(m_d_y,v_d.y)
       endelse
       
       if(size(v_t,/n_dim) eq 0 && v_t eq -1L) then begin
          dprint,'FX failed to perform mx operation'
          return
       endif
    
       ;update meta data
       ;and store output
    
        ;if the vector dlimits struct is unavailable create one
        if(size(v_dl,/n_dim) eq 0 && v_dl eq 0) then begin
            dprint,'dlimits for input vector should be set'
            dprint,'Creating default dlimits structure'
    
            v_data_att = {coord_sys:'undefined',units:''}
            v_dl = {data_att:v_data_att,labflag:0,labels:make_array(v_d_s[1],/string,value='')}
    
        endif
    
        ;if the matrix dlimits struct is unavailable create one
        if(size(m_dl,/n_dim) eq 0 && m_dl eq 0) then begin
            dprint,'m_dl coord_sys unset, unable to make coordinate system determination'
            
            m_data_att = {coord_sys:'undefined',units:'',source_sys:'undefined'}
            m_dl = {data_att:m_data_att,labflag:0,labels:make_array(v_d_s[1],/string,value='')}
        endif
    
    
        ;make sure it has data_att
        str_element,v_dl,'data_att',SUCCESS=s
    
        if(s eq 0) then begin
    
            v_data_att = {coord_sys:'undefined',units:''}
            
            str_element,/add,v_dl,'data_att',v_data_att
    
        endif
    
        ;make sure it has ytitle
    
        str_element,v_dl,'ytitle',SUCCESS=s
    
        if(s eq 0) then begin
     
            v_ytitle = ''
    
            str_element,/add,v_dl,'ytitle',v_ytitle
    
        endif
    
        ;make sure it has appropriate data_att elements
        str_element,v_dl.data_att,'coord_sys',SUCCESS=s
    
        if(s eq 0) then begin
    
            v_data_att = v_dl.data_att 
    
            str_element,/add,v_data_att,'coord_sys','undefined'
    
            str_element,/add,v_dl,'data_att',v_data_att
    
            
        endif
    
        str_element,v_dl.data_att,'units',SUCCESS=s
    
        if(s eq 0) then begin
    
            v_data_att = v_dl.data_att 
    
            str_element,/add,v_data_att,'units',''
    
            str_element,/add,v_dl,'data_att',v_data_att
    
        endif
        
        str_element,m_dl,'data_att.coord_sys',success=s
        
        if s eq 0 then begin
          str_element,m_dl,'data_att.coord_sys','unknown',/add_replace
        endif
        
        str_element,m_dl,'data_att.source_sys',success=s
        
        if s eq 0 then begin
          str_element,m_dl,'data_att.source_sys','unknown',/add_replace
        endif
    
        if ~keyword_set(invert) then begin
         
          if v_dl.data_att.coord_sys ne 'unknown' && $
             m_dl.data_att.source_sys ne 'unknown' && $
             v_dl.data_att.coord_sys ne m_dl.data_att.source_sys then begin
             dprint,'WARNING: Source coordinates of input vectors do not match expected input for transformation matrixes'     
          endif
             
        
          v_dl.data_att.coord_sys = m_dl.data_att.coord_sys
        endif else begin
          
          if v_dl.data_att.coord_sys ne 'unknown' && $
             m_dl.data_att.coord_sys ne 'unknown' && $
             v_dl.data_att.coord_sys ne m_dl.data_att.coord_sys then begin
             dprint,'WARNING: Source coordinates of input vectors do not match expected input for inverted transformation matrixes'     
          endif
          
          v_dl.data_att.coord_sys = m_dl.data_att.source_sys
        endelse
        
    ;    if keyword_set(invert) then begin
    ;      v_dl.data_att.units = v_dl.data_att.units+'_irot'
    ;    endif else begin
    ;      v_dl.data_att.units = v_dl.data_att.units+'_rot'
    ;    endelse
    ;    
    ;    v_dl.ytitle = newname[i] + '!C' + v_dl.data_att.units
         
    
        ;no longer take labels from transformation matrix
        ;if m_dl.labflag eq 1 then v_dl.labels = m_dl.labels
    
        str_element,v_d,'v',SUCCESS=s
    
        if(s) then $
          v_d = {x:v_d.x,y:v_t,v:v_d.v} $
        else $
          v_d = {x:v_d.x,y:v_t} 
    
        store_data,newname[i],data=v_d,dlimits = v_dl
    
    endfor

endif else begin     ; end of tplotvar

   v_d = vec_var_in 
   v_d_s = size(v_d,/dimensions)

   m_d_y = mat_var_in
   verify_check = ctv_verify_mats(m_d_y)

   ;returns 0 if the matrices use a mixed system
   ;returns 1 if there are no valid mats
   ;returns 2 if the data are all nans
   ;returns 3 if there are some invalid mats
   ;returns 4 if there are some nans
   ;returns 5 win!
   if verify_check eq 0 then begin
     dprint,'ERROR: Input matrices contain rotations with determinants of both -1 and 1.  This may indicate an incorrectly formed rotation, or an high level of error in the rotation.',dlevel=1
   endif else if verify_check eq 1 then begin
     dprint,'ERROR: Input matrices are not valid rotation matries. This may indicate an incorrectly formed rotation, or an high level of error in the rotation.',dlevel=1
     ;decided against forced failure, as extreme numerical instability can create false positives for invalid tests
     ;return
   endif else if verify_check eq 2 then begin
     dprint,'ERROR: All input matrices contain non-finite values.(Infinity or NaN)   Results will be non-finite.',dlevel=1
   endif else if verify_check eq 3 then begin
     dprint,'WARNING: Some input matrices are not valid rotation matrices. You may want to verify the result',dlevel=2
   endif else if verify_check eq 4 then begin
     dprint,'WARNING: Some input matrices contain non-finite values.(Infinity or NaN)  Some results will be non-finite.' ,dlevel=2
   endif

   ;if invert is set, then we transpose rotation matrices to construct inverse rotation matrix
   if keyword_set(invert) then begin
      newname = ctv_mx_vec_rot(transpose(m_d_y,[0,2,1]),v_d)
   endif else begin
      newname = ctv_mx_vec_rot(m_d_y,v_d)
   endelse
          
endelse    ; end of vector data
   
error = 1

return

end