/**
 * Copyright 2019 Pinterest, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

namespace py schemas.loggingaudit
namespace java com.pinterest.singer.loggingaudit.thrift.configuration

include "loggingaudit.thrift"
include "common.thrift"


/**
 *  AuditEvent sender type.
 **/
enum SenderType {
   KAFKA = 0
}

/**
 *  audit config for each topic/logstream.
 **/
struct AuditConfig{

   /**
    *  samplingRate specify the percent of log messages are going to be audited. This field needs to
    *  be set in two cases:
    *  (1) messages are logged by thrift logger and this field needs to be set only at ThriftLogger
    *      stage, not the following stages such as Singer and Merced.
    *  (2) Messages are not generated by thrift logger and Singer is the first stage of thet pipeline,
    *      for example, Singer can be configured to upload server logs (in text format).
    */
    1: optional double samplingRate = 1.0;

   /**
    *  flag indicates whether current stage is the start of logging auditing. For ThriftLogger stage,
    *  the value is always true. At Singer stage, this field can be true if Singer uploads log files
    *  not generated by ThriftLogger, for example server logs in text format. For other
    *  stages, this field is always false.
    */
    2: optional bool startAtCurrentStage = true;

   /**
    *  flag indicates whether current stage is the end of the logging auditing. This field can be
    *  true at Merced / Merced_HR stage.
    */
    3: optional bool stopAtCurrentStage = false;
}


/**
 *  KakfaSenderConfig consists of kafka topic name and kafka producer config.
 **/
struct KafkaSenderConfig {
    1: optional string topic = "logging_audit";
    2: optional common.KafkaProducerConfig kafkaProducerConfig;
    3: optional i32 stopGracePeriodInSeconds = 30;
}

/**
 *  LoggingAuditEventSenderConfig consists of senderType (only support Kafka at the moment
 *  and KafkaSenderConfig.
 **/
struct LoggingAuditEventSenderConfig {
    1: optional SenderType senderType = SenderType.KAFKA;
    2: optional KafkaSenderConfig kafkaSenderConfig;
}

/**
 *  Configurations for creating LoggingAuditClient which is imported at different LoggingAudit
 *  stages to generate and send LoggingAuditEvent to external systems (eg: Kafka Cluster).
 **/
struct LoggingAuditClientConfig {

   /**
    * LoggingAudit stage (must specified)
    */
    1: required loggingaudit.LoggingAuditStage stage;

   /**
    * configuration for LoggingAuditEventSender (must specified to create LoggingAuditEventSender).
    */
    2: required LoggingAuditEventSenderConfig senderConfig ;

   /**
    * flag whether to enable LoggingAudit for all topics. Default is false.
    */
    3: optional bool enableAuditForAllTopicsByDefault = false;

   /**
    * size of the ArrayBlockingQueue which stores the LoggingAuditEvents. Thrift loggers, Singer
    * writers and Merced workers will enqueue LoggingAuditEvents and LoggingAuditEventSender will
    * dequeue LoggingAuditEvents and send to external systems (Kafka cluster). Default queue size
    * is 100,000.
    */
    5: optional i32 queueSize = 100000;

   /**
    * This field specifies how long the enqueueing thread can be blocked. Default value is 0 which
    * means no blocking and this LoggingAuditEvent will be dropped.
    */
    6: optional i32 enqueueWaitInMilliseconds = 0;

   /**
    * Key of the map is the name of (1) topic or log file at ThriftLogger stage, (2) Singer log
    * config file name at Singer stage (3) Zookeeper connection plus topic name at Merced stage.
    *
    * Value of the map is AuditConfig.
    */
    7: optional map<string, AuditConfig> auditConfigs;
}