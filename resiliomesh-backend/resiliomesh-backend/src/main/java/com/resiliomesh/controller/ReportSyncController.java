package com.resiliomesh.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.resiliomesh.dto.SyncReportRequest;
import com.resiliomesh.model.ReportEntity;
import com.resiliomesh.repository.ReportRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Paths;
import java.util.*;

@RestController
@RequestMapping("/api/v1")
@CrossOrigin(
    origins = "*", 
    allowedHeaders = "*", 
    methods = {RequestMethod.GET, RequestMethod.POST, RequestMethod.PUT, RequestMethod.DELETE, RequestMethod.PATCH, RequestMethod.OPTIONS}
)
public class ReportSyncController {

    @Autowired
    private ReportRepository reportRepository;

    // Direct uploads directory under root/user home
    private static final String UPLOAD_DIR = System.getProperty("user.home") + File.separator + "resiliomesh_uploads" + File.separator;

    /**
     * Endpoint 1: Accepts JSON List payloads sent directly from Flutter SyncService
     * Routes: /api/v1/sos/sync, /api/v1/reports/sync
     */
    @PostMapping(value = {"/sos/sync", "/reports/sync"}, consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> syncJsonReports(@RequestBody List<SyncReportRequest> reportList) {
        try {
            List<String> syncedIds = new ArrayList<>();

            for (SyncReportRequest reportDto : reportList) {
                ReportEntity entity = reportRepository.findByReportId(reportDto.getReportId())
                        .orElse(new ReportEntity());

                entity.setReportId(reportDto.getReportId());
                entity.setSenderName(reportDto.getSenderName());
                entity.setMobileNumber(reportDto.getMobileNumber());
                entity.setTitle(reportDto.getTitle());
                entity.setDescription(reportDto.getDescription());
                
                // Safe null checks with default values
                entity.setLatitude(reportDto.getLatitude() != null ? reportDto.getLatitude() : 0.0);
                entity.setLongitude(reportDto.getLongitude() != null ? reportDto.getLongitude() : 0.0);
                entity.setPriority(reportDto.getPriority() != null ? reportDto.getPriority() : 1.0);
                
                if (reportDto.getTimestamp() != null) {
                    entity.setTimestamp(String.valueOf(reportDto.getTimestamp()));
                }
                
                entity.setStatus("SYNCED");

                // Clean legacy Android paths to ensure web accessibility
                if (reportDto.getMediaPaths() != null && !reportDto.getMediaPaths().trim().isEmpty()) {
                    String cleanMediaPaths = sanitizeMediaPaths(reportDto.getMediaPaths());
                    entity.setMediaUrls(cleanMediaPaths);
                }

                reportRepository.save(entity);
                syncedIds.add(reportDto.getReportId());
            }

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Reports synced successfully");
            response.put("count", syncedIds.size());
            response.put("syncedReportIds", syncedIds);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error processing JSON sync payload: " + e.getMessage());
        }
    }

    /**
     * Endpoint 2: Accepts multipart/form-data for syncing with attached media files
     * Routes: /api/v1/sos/sync-multipart, /api/v1/reports/sync-multipart, /api/v1/reports/upload
     */
    @PostMapping(
        value = {"/sos/sync-multipart", "/reports/sync-multipart", "/reports/upload"}, 
        consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<?> syncOffGridReports(
            @RequestPart("report") String reportJson,
            @RequestPart(value = "files", required = false) List<MultipartFile> files) {

        try {
            ObjectMapper objectMapper = new ObjectMapper();
            SyncReportRequest reportDto = objectMapper.readValue(reportJson, SyncReportRequest.class);

            File uploadFolder = new File(UPLOAD_DIR);
            if (!uploadFolder.exists()) {
                uploadFolder.mkdirs();
            }

            List<String> savedMediaUrls = new ArrayList<>();
            
            // Save physical files into UPLOAD_DIR
            if (files != null && !files.isEmpty()) {
                for (MultipartFile file : files) {
                    if (!file.isEmpty()) {
                        String rawFileName = file.getOriginalFilename() != null ? file.getOriginalFilename() : "file";
                        String cleanFileName = new File(rawFileName).getName(); 
                        
                        File destinationFile = new File(uploadFolder, cleanFileName);
                        file.transferTo(destinationFile);
                        
                        System.out.println("Saved file to: " + destinationFile.getAbsolutePath());
                        savedMediaUrls.add("/uploads/" + cleanFileName);
                    }
                }
            }

            ReportEntity entity = reportRepository.findByReportId(reportDto.getReportId())
                    .orElse(new ReportEntity());

            entity.setReportId(reportDto.getReportId());
            entity.setSenderName(reportDto.getSenderName());
            entity.setMobileNumber(reportDto.getMobileNumber());
            entity.setTitle(reportDto.getTitle());
            entity.setDescription(reportDto.getDescription());
            entity.setLatitude(reportDto.getLatitude() != null ? reportDto.getLatitude() : 0.0);
            entity.setLongitude(reportDto.getLongitude() != null ? reportDto.getLongitude() : 0.0);
            entity.setPriority(reportDto.getPriority() != null ? reportDto.getPriority() : 1.0);
            
            if (reportDto.getTimestamp() != null) {
                entity.setTimestamp(String.valueOf(reportDto.getTimestamp()));
            }
            
            entity.setStatus("SYNCED");
            
            if (!savedMediaUrls.isEmpty()) {
                entity.setMediaUrls(String.join(",", savedMediaUrls));
            } else if (reportDto.getMediaPaths() != null && !reportDto.getMediaPaths().trim().isEmpty()) {
                entity.setMediaUrls(sanitizeMediaPaths(reportDto.getMediaPaths()));
            }

            reportRepository.save(entity);

            Map<String, String> response = new HashMap<>();
            response.put("message", "Report synced successfully");
            response.put("reportId", reportDto.getReportId());

            return ResponseEntity.status(HttpStatus.OK).body(response);

        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error processing sync payload: " + e.getMessage());
        }
    }

    /**
     * Endpoint 3: Retrieves all reports for the Admin Web Panel and mobile app
     * Routes: /api/v1/reports/all, /api/v1/sos/all
     */
    @GetMapping(value = {"/reports/all", "/sos/all"})
    public ResponseEntity<List<ReportEntity>> getAllReports() {
        return ResponseEntity.ok(reportRepository.findAll());
    }

    /**
     * Endpoint 4: Deletes a specific emergency report by reportId string
     * Route: DELETE /api/v1/reports/by-id/{reportId}
     */
    @DeleteMapping("/reports/by-id/{reportId}")
    public ResponseEntity<String> deleteReport(@PathVariable String reportId) {
        Optional<ReportEntity> reportOpt = reportRepository.findByReportId(reportId);
        if (reportOpt.isPresent()) {
            reportRepository.delete(reportOpt.get());
            return ResponseEntity.ok("Report deleted successfully");
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Report not found");
    }

    /**
     * Endpoint 5: Marks a specific emergency report status as RESOLVED by reportId string
     * Route: PATCH /api/v1/reports/by-id/{reportId}/resolve
     */
    @PatchMapping("/reports/by-id/{reportId}/resolve")
    public ResponseEntity<String> resolveReport(@PathVariable String reportId) {
        Optional<ReportEntity> reportOpt = reportRepository.findByReportId(reportId);
        if (reportOpt.isPresent()) {
            ReportEntity report = reportOpt.get();
            report.setStatus("RESOLVED");
            reportRepository.save(report);
            return ResponseEntity.ok("Report marked as resolved");
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Report not found");
    }

    /**
     * Endpoint 6: Assigns a response team to a specific emergency report by reportId string
     * Route: PATCH /api/v1/reports/by-id/{reportId}/assign
     */
   /**
     * Endpoint 6: Assigns a response team to a specific emergency report by reportId string
     * Route: PATCH /api/v1/reports/by-id/{reportId}/assign
     */
    @PatchMapping("/reports/by-id/{reportId}/assign")
    public ResponseEntity<String> assignTeam(
            @PathVariable String reportId, 
            @RequestParam("team") String team) {
        Optional<ReportEntity> reportOpt = reportRepository.findByReportId(reportId);
        if (reportOpt.isPresent()) {
            ReportEntity report = reportOpt.get();
            report.setAssignedTeam(team);
            reportRepository.save(report);
            return ResponseEntity.ok("Team assigned successfully");
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Report not found");
    }


    /**
     * Internal helper to strip local Android device paths and format relative web paths
     */
    private String sanitizeMediaPaths(String rawPaths) {
        if (rawPaths == null || rawPaths.trim().isEmpty()) return "";
        
        List<String> cleanPaths = new ArrayList<>();
        String[] paths = rawPaths.split(",");
        
        for (String path : paths) {
            String trimmed = path.trim();
            if (!trimmed.isEmpty()) {
                String fileName = new File(trimmed).getName();
                cleanPaths.add("/uploads/" + fileName);
            }
        }
        return String.join(",", cleanPaths);
    }
}